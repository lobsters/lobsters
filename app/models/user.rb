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
  belongs_to :disabled_invite_by_user,
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
  has_many :hats

  has_secure_password

  typed_store :settings do |s|
    s.boolean :email_notifications, :default => false
    s.boolean :email_replies, :default => false
    s.boolean :pushover_replies, :default => false
    s.string :pushover_user_key
    s.boolean :email_messages, :default => false
    s.boolean :pushover_messages, :default => false
    s.boolean :email_mentions, :default => false
    s.boolean :show_avatars, :default => true
    s.boolean :show_story_previews, :default => false
    s.boolean :show_submitted_story_threads, :default => false
    s.boolean :hide_dragons, :default => false
    s.string :totp_secret
    s.string :github_oauth_token
    s.string :github_username
    s.string :twitter_oauth_token
    s.string :twitter_oauth_token_secret
    s.string :twitter_username
  end

  validates :email, :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ },
    :uniqueness => { :case_sensitive => false }

  validates :password, :presence => true, :on => :create

  VALID_USERNAME = /[A-Za-z0-9][A-Za-z0-9_-]{0,24}/
  validates :username,
    :format => { :with => /\A#{VALID_USERNAME}\z/ },
    :uniqueness => { :case_sensitive => false }

  validates_each :username do |record,attr,value|
    if BANNED_USERNAMES.include?(value.to_s.downcase)
      record.errors.add(attr, "is not permitted")
    end
  end

  scope :active, -> { where(:banned_at => nil, :deleted_at => nil) }

  before_save :check_session_token
  before_validation :on => :create do
    self.create_rss_token
    self.create_mailing_list_token
  end
  after_create :update_invitations_sent_count!

  BANNED_USERNAMES = [ "admin", "administrator", "contact", "fraud", "guest",
    "help", "hostmaster", "mailer-daemon", "moderator", "moderators", "nobody",
    "postmaster", "root", "security", "support", "sysop", "webmaster" ]

  # days old accounts are considered new for
  NEW_USER_DAYS = 7

  # minimum karma required to be able to offer title/tag suggestions
  MIN_KARMA_TO_SUGGEST = 10

  # minimum karma required to be able to downvote comments
  MIN_KARMA_TO_DOWNVOTE = 50

  # minimum karma required to be able to submit new stories
  MIN_KARMA_TO_SUBMIT_STORIES = -4

  def self.recalculate_all_karmas!
    User.all.each do |u|
      u.karma = u.stories.map(&:score).sum + u.comments.map(&:score).sum
      u.save!
    end
  end

  def self.username_regex_s
    "/^" + VALID_USERNAME.to_s.gsub(/(\?-mix:|\(|\))/, "") + "$/"
  end

  def as_json(options = {})
    attrs = [
      :username,
      :created_at,
      :is_admin,
      :is_moderator,
    ]

    if !self.is_admin?
      attrs.push :karma
    end

    attrs.push :about

    h = super(:only => attrs)

    h[:avatar_url] = self.avatar_url

    if self.github_username.present?
      h[:github_username] = self.github_username
    end

    if self.twitter_username.present?
      h[:twitter_username] = self.twitter_username
    end

    h
  end

  def authenticate_totp(code)
    totp = ROTP::TOTP.new(self.totp_secret)
    totp.verify(code)
  end

  def avatar_url(size = 100)
    "https://secure.gravatar.com/avatar/" +
      Digest::MD5.hexdigest(self.email.strip.downcase) +
      "?r=pg&d=identicon&s=#{size}"
  end

  def average_karma
    if (k = self.karma) == 0
      0
    else
      k.to_f / (self.stories_submitted_count + self.comments_posted_count)
    end
  end

  def disable_invite_by_user_for_reason!(disabler, reason)
    self.disabled_invite_at = Time.now
    self.disabled_invite_by_user_id = disabler.id
    self.disabled_invite_reason = reason

    msg = Message.new
    msg.deleted_by_author = true
    msg.author_user_id = disabler.id
    msg.recipient_user_id = self.id
    msg.subject = "Your invite privileges have been revoked"
    msg.body = "The reason given:\n" <<
      "\n" <<
      "> *#{reason}*\n" <<
      "\n" <<
      "*This is an automated message.*"
    msg.save

    m = Moderation.new
    m.moderator_user_id = disabler.id
    m.user_id = self.id
    m.action = "Disabled invitations"
    m.reason = reason
    m.save!

    true
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

  def banned_from_inviting?
    disabled_invite_at?
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
    elsif obj.is_a?(Comment) && obj.is_downvotable?
      return !self.is_new? && (self.karma >= MIN_KARMA_TO_DOWNVOTE)
    end

    false
  end

  def can_invite?
    # admins and moderators can always invite
    if self.is_admin || self.is_moderator
      return true
    end

    # banned users can never invite
    if banned_from_inviting? or !self.can_submit_stories?
      return false
    end

    # during closed testing, a maximum of max_invitations_count invites can be sent
    if Rails.application.closed_testing?
      return self.invitations_sent_count < Rails.application.max_invitations_count
    end

    # usually there is not limit on the number of invites
    return true
  end

  def can_offer_suggestions?
    !self.is_new? && (self.karma >= MIN_KARMA_TO_SUGGEST)
  end

  def can_submit_stories?
    self.karma >= MIN_KARMA_TO_SUBMIT_STORIES
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

  def update_comments_posted_count!
    Keystore.put("user:#{self.id}:comments_posted", self.comments.active.count)
  end

  def invitations_sent_count
    Keystore.value_for("user:#{self.id}:invitations_sent").to_i
  end

  def update_invitations_sent_count!
    Keystore.put("user:#{self.id}:invitations_sent", self.invitations.count)
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

  def undelete!
    User.transaction do
      self.comments.each{|c| c.undelete_for_user(self) }

      self.sent_messages.each do |m|
        m.deleted_by_author = false
        m.save
      end
      self.received_messages.each do |m|
        m.deleted_by_recipient = false
        m.save
      end

      self.deleted_at = nil
      self.save!
    end
  end

  def disable_2fa!
    self.totp_secret = nil
    self.save!
  end

  def grant_moderatorship_by_user!(user)
    User.transaction do
      self.is_moderator = true
      self.save!

      m = Moderation.new
      m.moderator_user_id = user.id
      m.user_id = self.id
      m.action = "Granted moderator status"
      m.save!

      h = Hat.new
      h.user_id = self.id
      h.granted_by_user_id = user.id
      h.hat = "Sysop"
      h.save!
    end

    true
  end

  def initiate_password_reset_for_ip(ip)
    self.password_reset_token = "#{Time.now.to_i}-#{Utils.random_str(30)}"
    self.save!

    PasswordReset.password_reset_link(self, ip).deliver_now
  end

  def has_2fa?
    self.totp_secret.present?
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
    Markdowner.to_html(self.about)
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
      Pushover.push(self.pushover_user_key, params)
    end
  end

  def recent_threads(amount, include_submitted_stories = false)
    thread_ids = self.comments.group(:thread_id).order('MAX(created_at) DESC').
      limit(amount).pluck(:thread_id)

    if include_submitted_stories && self.show_submitted_story_threads
      thread_ids += Comment.joins(:story).
        where(:stories => { :user_id => self.id }).group(:thread_id).
        order("MAX(comments.created_at) DESC").limit(amount).pluck(:thread_id)

      thread_ids = thread_ids.uniq.sort.reverse[0, amount]
    end

    thread_ids
  end

  def stories_submitted_count
    Keystore.value_for("user:#{self.id}:stories_submitted").to_i
  end

  def to_param
    username
  end

  def unban_by_user!(unbanner)
    self.banned_at = nil
    self.banned_by_user_id = nil
    self.banned_reason = nil
    self.deleted_at = nil
    self.save!

    m = Moderation.new
    m.moderator_user_id = unbanner.id
    m.user_id = self.id
    m.action = "Unbanned"
    m.save!

    true
  end

  def enable_invite_by_user!(mod)
    self.disabled_invite_at = nil
    self.disabled_invite_by_user_id = nil
    self.disabled_invite_reason = nil
    self.save!

    m = Moderation.new
    m.moderator_user_id = mod.id
    m.user_id = self.id
    m.action = "Enabled invitations"
    m.save!

    true
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

  def unread_replies_count
    ReplyingComment.where(user_id: self.id, is_unread: true).count
  end

  def update_unread_message_count!
    Keystore.put("user:#{self.id}:unread_messages",
      self.received_messages.unread.count)
  end

  def votes_for_others
    self.votes.joins(:story, :comment).
      where("comments.user_id <> votes.user_id AND " <<
        "stories.user_id <> votes.user_id").
      order("id DESC")
  end
end
