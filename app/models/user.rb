class User < ActiveRecord::Base
  has_many :stories,
    -> { includes :user }
  has_many :comments
  has_many :sent_messages,
    :class_name => "Message",
    :foreign_key => "author_user_id"
  has_many :received_messages,
    :class_name => "Message",
    :foreign_key => "recipient_user_id"
  has_many :tag_filters
  has_many :tag_filter_tags,
    :class_name => "Tag",
    :through => :tag_filters,
    :source => :tag,
    :dependent => :delete_all
  belongs_to :invited_by_user,
    :class_name => "User"
  belongs_to :banned_by_user,
    :class_name => "User"
  has_many :invitations
  has_many :votes
  has_many :voted_stories, -> { where('votes.comment_id' => nil) },
    :through => :votes,
    :source => :story
  has_many :upvoted_stories,
    -> { where('votes.comment_id' => nil, 'votes.vote' => 1) },
    :through => :votes,
    :source => :story

  has_secure_password

  validates :email, :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ },
    :uniqueness => { :case_sensitive => false }

  validates :password, :presence => true, :on => :create

  validates :username,
    :format => { :with => /\A[A-Za-z0-9][A-Za-z0-9_-]{0,24}\Z/ },
    :uniqueness => { :case_sensitive => false }

  validates_each :username do |record,attr,value|
    if BANNED_USERNAMES.include?(value.to_s.downcase)
      record.errors.add(attr, "is not permitted")
    end
  end

  before_save :check_session_token
  before_validation :on => :create do
    self.create_rss_token
    self.create_mailing_list_token
  end

  BANNED_USERNAMES = [ "admin", "administrator", "hostmaster", "mailer-daemon",
    "postmaster", "root", "security", "support", "webmaster", "moderator",
    "moderators", ]

  # days old accounts are considered new for
  NEW_USER_DAYS = 7

  def self.recalculate_all_karmas!
    User.all.each do |u|
      u.karma = u.stories.map(&:score).sum + u.comments.map(&:score).sum
      u.save!
    end
  end

  def self.username_regex
    User.validators_on(:username).select{|v|
      v.class == ActiveModel::Validations::FormatValidator }.first.
      options[:with].inspect
  end

  def as_json(options = {})
    h = super(:only => [
      :username,
      :created_at,
      :is_admin,
      :is_moderator,
    ])
    h[:avatar_url] = avatar_url
    h
  end

  def avatar_url
    "https://secure.gravatar.com/avatar/" +
      Digest::MD5.hexdigest(self.email.strip.downcase) + "?r=pg&d=mm&s=100"
  end

  def average_karma
    if (k = self.karma) == 0
      0
    else
      k.to_f / (self.stories_submitted_count + self.comments_posted_count)
    end
  end

  def ban_by_user_for_reason!(banner, reason)
    self.banned_at = Time.now
    self.banned_by_user_id = banner.id
    self.banned_reason = reason

    self.delete!

    BanNotification.notify(self, banner, reason)

    m = Moderation.new
    m.moderator_user_id = banner.id
    m.user_id = self.id
    m.action = "Banned"
    m.reason = reason
    m.save!

    true
  end

  def can_downvote?(obj)
    if is_new?
      return false
    elsif obj.is_a?(Story)
      if obj.is_downvotable?
        return true
      elsif obj.vote == -1
        # user can unvote
        return true
      end
    elsif obj.is_a?(Comment)
      if obj.is_downvotable?
        return true
      elsif obj.current_vote.try(:vote).to_i == -1
        # user can unvote
        return true
      end
    end

    false
  end

  def check_session_token
    if self.session_token.blank?
      self.session_token = Utils.random_str(60)
    end
  end

  def create_mailing_list_token
    if self.mailing_list_token.blank?
      self.mailing_list_token = Utils.random_str(10)
    end
  end

  def create_rss_token
    if self.rss_token.blank?
      self.rss_token = Utils.random_str(60)
    end
  end

  def comments_posted_count
    Keystore.value_for("user:#{self.id}:comments_posted").to_i
  end

  def delete!
    User.transaction do
      self.comments.each{|c| c.delete_for_user(self) }

      self.sent_messages.each do |m|
        m.deleted_by_author = true
        m.save
      end
      self.received_messages.each do |m|
        m.deleted_by_recipient = true
        m.save
      end

      self.invitations.destroy_all

      self.session_token = nil
      self.check_session_token

      self.deleted_at = Time.now
      self.save!
    end
  end

  def initiate_password_reset_for_ip(ip)
    self.password_reset_token = "#{Time.now.to_i}-#{Utils.random_str(30)}"
    self.save!

    PasswordReset.password_reset_link(self, ip).deliver
  end

  def is_active?
    !(deleted_at? || is_banned?)
  end

  def is_banned?
    banned_at?
  end

  def is_new?
    Time.now - self.created_at <= NEW_USER_DAYS.days
  end

  def linkified_about
    # most users are probably mentioning "@username" to mean a twitter url, not
    # a link to a profile on this site
    Markdowner.to_html(self.about, { :disable_profile_links => true })
  end

  def most_common_story_tag
    Tag.active.joins(
      :stories
    ).where(
      :stories => { :user_id => self.id }
    ).group(
      Tag.arel_table[:id]
    ).order(
      'COUNT(*) desc'
    ).first
  end

  def pushover!(params)
    if self.pushover_user_key.present?
      Pushover.push(self.pushover_user_key, self.pushover_device,
        params.merge({ :sound => self.pushover_sound.to_s }))
    end
  end

  def recent_threads(amount)
    self.comments.group(:thread_id).order('MAX(created_at) DESC').limit(
      amount).pluck(:thread_id)
  end

  def stories_submitted_count
    Keystore.value_for("user:#{self.id}:stories_submitted").to_i
  end

  def to_param
    username
  end

  def unban!
    self.banned_at = nil
    self.banned_by_user_id = nil
    self.banned_reason = nil
    self.save!
  end

  def undeleted_received_messages
    received_messages.where(:deleted_by_recipient => false)
  end

  def undeleted_sent_messages
    sent_messages.where(:deleted_by_author => false)
  end

  def unread_message_count
    Keystore.value_for("user:#{self.id}:unread_messages").to_i
  end

  def update_unread_message_count!
    Keystore.put("user:#{self.id}:unread_messages",
      Message.where("recipient_user_id = ? AND (has_been_read = ? AND " <<
      "deleted_by_recipient = ?)", self.id, false, false).count)
  end
end
