class User < ApplicationRecord
  has_many :stories, -> { includes :user }, :inverse_of => :user
  has_many :comments,
           :inverse_of => :user,
           :dependent => :restrict_with_exception
  has_many :sent_messages,
           :class_name => "Message",
           :foreign_key => "author_user_id",
           :inverse_of => :author,
           :dependent => :restrict_with_exception
  has_many :received_messages,
           :class_name => "Message",
           :foreign_key => "recipient_user_id",
           :inverse_of => :recipient,
           :dependent => :restrict_with_exception
  has_many :tag_filters, :dependent => :destroy
  has_many :tag_filter_tags,
           :class_name => "Tag",
           :through => :tag_filters,
           :source => :tag,
           :dependent => :delete_all
  belongs_to :invited_by_user,
             :class_name => "User",
             :inverse_of => false,
             :optional => true
  belongs_to :banned_by_user,
             :class_name => "User",
             :inverse_of => false,
             :optional => true
  belongs_to :disabled_invite_by_user,
             :class_name => "User",
             :inverse_of => false,
             :optional => true
  has_many :invitations, :dependent => :destroy
  has_many :moderations,
           :inverse_of => :moderator,
           :dependent => :restrict_with_exception
  has_many :votes, :dependent => :destroy
  has_many :voted_stories, -> { where('votes.comment_id' => nil) },
           :through => :votes,
           :source => :story
  has_many :upvoted_stories,
           -> {
             where('votes.comment_id' => nil, 'votes.vote' => 1)
             .where('stories.user_id != votes.user_id')
           },
           :through => :votes,
           :source => :story
  has_many :hats, :dependent => :destroy
  has_many :wearable_hats, -> { where('doffed_at is null') },
           :class_name => "Hat",
           :inverse_of => :user

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
    s.string :totp_secret
    s.string :github_oauth_token
    s.string :github_username
    s.string :twitter_oauth_token
    s.string :twitter_oauth_token_secret
    s.string :twitter_username
    s.any :keybase_signatures, array: true
    s.string :homepage
  end

  validates :email,
            :length => { :maximum => 100 },
            :format => { :with => /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/ },
            :uniqueness => { :case_sensitive => false }

  validates :homepage,
            :format => { :with => /\Ahttps?:\/\/[^\/\s]+\.[^.\/\s]+(\/.*)?\Z/ },
            :allow_blank => true

  validates :password, :presence => true, :on => :create

  VALID_USERNAME = /[A-Za-z0-9][A-Za-z0-9_-]{0,24}/.freeze
  validates :username,
            :format => { :with => /\A#{VALID_USERNAME}\z/ },
            :length => { :maximum => 50 },
            :uniqueness => { :case_sensitive => false }

  validates :password_reset_token,
            :length => { :maximum => 75 }
  validates :session_token,
            :length => { :maximum => 75 }
  validates :about,
            :length => { :maximum => 16_777_215 }
  validates :rss_token,
            :length => { :maximum => 75 }
  validates :mailing_list_token,
            :length => { :maximum => 75 }
  validates :banned_reason,
            :length => { :maximum => 200 }
  validates :disabled_invite_reason,
            :length => { :maximum => 200 }

  validates_each :username do |record, attr, value|
    if BANNED_USERNAMES.include?(value.to_s.downcase) || value.starts_with?('tag-')
      record.errors.add(attr, "is not permitted")
    end
  end

  scope :active, -> { where(:banned_at => nil, :deleted_at => nil) }
  scope :moderators, -> {
    where('
      is_moderator = True OR
      users.id IN (select distinct moderator_user_id from moderations)
    ')
  }

  before_save :check_session_token
  before_validation :on => :create do
    self.create_rss_token
    self.create_mailing_list_token
  end

  BANNED_USERNAMES = ["admin", "administrator", "contact", "fraud", "guest",
    "help", "hostmaster", "lobster", "lobsters", "mailer-daemon", "moderator",
    "moderators", "nobody", "postmaster", "root", "security", "support",
    "sysop", "webmaster", "enable", "new", "signup",].freeze

  # days old accounts are considered new for
  NEW_USER_DAYS = 70

  # minimum karma required to be able to offer title/tag suggestions
  MIN_KARMA_TO_SUGGEST = 10

  # minimum karma required to be able to downvote comments
  MIN_KARMA_TO_DOWNVOTE = 50

  # minimum karma required to be able to submit new stories
  MIN_KARMA_TO_SUBMIT_STORIES = -4

  # minimum karma required to process invitation requests
  MIN_KARMA_FOR_INVITATION_REQUESTS = MIN_KARMA_TO_DOWNVOTE

  # proportion of posts authored by user to consider as heavy self promoter
  HEAVY_SELF_PROMOTER_PROPORTION = 0.51

  # minimum number of submitted stories before checking self promotion
  MIN_STORIES_CHECK_SELF_PROMOTION = 2

  def self.username_regex_s
    "/^" + VALID_USERNAME.to_s.gsub(/(\?-mix:|\(|\))/, "") + "$/"
  end

  def as_json(_options = {})
    attrs = [
      :username,
      :created_at,
      :is_admin,
      :is_moderator,
    ]

    if !self.is_admin?
      attrs.push :karma
    end

    attrs.push :homepage, :about

    h = super(:only => attrs)

    h[:avatar_url] = self.avatar_url
    h[:invited_by_user] = User.where(id: invited_by_user_id).pluck(:username).first

    if self.github_username.present?
      h[:github_username] = self.github_username
    end

    if self.twitter_username.present?
      h[:twitter_username] = self.twitter_username
    end

    if self.keybase_signatures.present?
      h[:keybase_signatures] = self.keybase_signatures
    end

    h
  end

  def authenticate_totp(code)
    totp = ROTP::TOTP.new(self.totp_secret)
    totp.verify(code)
  end

  def avatar_path(size = 100)
    ActionController::Base.helpers.image_path(
      "/avatars/#{self.username}-#{size}.png",
      skip_pipeline: true
    )
  end

  def avatar_url(size = 100)
    ActionController::Base.helpers.image_url(
      "/avatars/#{self.username}-#{size}.png",
      skip_pipeline: true
    )
  end

  def average_karma
    if self.karma == 0
      0
    else
      self.karma.to_f / (self.stories_submitted_count + self.comments_posted_count)
    end
  end

  def disable_invite_by_user_for_reason!(disabler, reason)
    User.transaction do
      self.disabled_invite_at = Time.current
      self.disabled_invite_by_user_id = disabler.id
      self.disabled_invite_reason = reason
      self.save!

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
      msg.save!

      m = Moderation.new
      m.moderator_user_id = disabler.id
      m.user_id = self.id
      m.action = "Disabled invitations"
      m.reason = reason
      m.save!
    end

    true
  end

  def ban_by_user_for_reason!(banner, reason)
    User.transaction do
      self.banned_at = Time.current
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
    end

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
    !self.is_new? && !banned_from_inviting? && self.can_submit_stories?
  end

  def can_offer_suggestions?
    !self.is_new? && (self.karma >= MIN_KARMA_TO_SUGGEST)
  end

  def can_see_invitation_requests?
    can_invite? && (self.is_moderator? ||
      (self.karma >= MIN_KARMA_FOR_INVITATION_REQUESTS))
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

  def comments_deleted_count
    Keystore.value_for("user:#{self.id}:comments_deleted").to_i
  end

  def fetched_avatar(size = 100)
    gravatar_url = "https://www.gravatar.com/avatar/" <<
                   Digest::MD5.hexdigest(self.email.strip.downcase) <<
                   "?r=pg&d=identicon&s=#{size}"

    begin
      s = Sponge.new
      s.timeout = 3
      res = s.fetch(gravatar_url).body
      if res.present?
        return res
      end
    rescue => e
      Rails.logger.error "error fetching #{gravatar_url}: #{e.message}"
    end

    nil
  end

  def refresh_counts!
    Keystore.put("user:#{self.id}:stories_submitted", self.stories.count)
    Keystore.put("user:#{self.id}:comments_posted", self.comments.active.count)
    Keystore.put("user:#{self.id}:comments_deleted", self.comments.deleted.count)
  end

  def delete!
    User.transaction do
      self.comments
        .where("upvotes - downvotes < 0")
        .find_each {|c| c.delete_for_user(self) }

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

      self.deleted_at = Time.current
      self.good_riddance?
      self.save!
    end
  end

  def undelete!
    User.transaction do
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

  # ensures some users talk to a mod before reactivating
  def good_riddance?
    return if self.is_banned? # https://www.youtube.com/watch?v=UcZzlPGnKdU
    self.email = "#{self.username}@lobsters.example" if \
      self.karma < 0 ||
      (self.comments.where('created_at >= now() - interval 30 day AND is_moderated').count +
       self.stories.where('created_at >= now() - interval 30 day AND is_expired AND is_moderated')
         .count >= 3) ||
      DownvotedCommenters.new('90d').check_list_for(self)
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
    self.password_reset_token = "#{Time.current.to_i}-#{Utils.random_str(30)}"
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

  # user was deleted/banned before a server move, see lib/tasks/privacy_wipe
  def is_wiped?
    password_digest == '*'
  end

  def is_new?
    return true unless self.created_at # unsaved object; in signup flow or a test
    Time.current - self.created_at <= NEW_USER_DAYS.days
  end

  def add_or_update_keybase_proof(kb_username, kb_signature)
    self.keybase_signatures ||= []
    self.remove_keybase_proof(kb_username)
    self.keybase_signatures.push('kb_username' => kb_username, 'sig_hash' => kb_signature)
  end

  def remove_keybase_proof(kb_username)
    self.keybase_signatures ||= []
    self.keybase_signatures.reject! {|kbsig| kbsig['kb_username'] == kb_username }
  end

  def is_heavy_self_promoter?
    total_count = self.stories_submitted_count

    if total_count < MIN_STORIES_CHECK_SELF_PROMOTION
      false
    else
      authored = self.stories.where(:user_is_author => true).count
      authored.to_f / total_count >= HEAVY_SELF_PROMOTER_PROPORTION
    end
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
      Arel.sql('COUNT(*) desc')
    ).first
  end

  def pushover!(params)
    if self.pushover_user_key.present?
      Pushover.push(self.pushover_user_key, params)
    end
  end

  def recent_threads(amount, include_submitted_stories: false, for_user: user)
    comments = self.comments.for_user(for_user)

    thread_ids = comments.group(:thread_id).order('MAX(created_at) DESC').limit(amount)
      .pluck(:thread_id)

    if include_submitted_stories && self.show_submitted_story_threads
      thread_ids += Comment.joins(:story)
        .where(:stories => { :user_id => self.id }).group(:thread_id)
        .order("MAX(comments.created_at) DESC").limit(amount).pluck(:thread_id)

      thread_ids = thread_ids.uniq.sort.reverse[0, amount]
    end

    thread_ids
  end

  def stories_submitted_count
    Keystore.value_for("user:#{self.id}:stories_submitted").to_i
  end

  def stories_deleted_count
    Keystore.value_for("user:#{self.id}:stories_deleted").to_i
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
    User.transaction do
      self.disabled_invite_at = nil
      self.disabled_invite_by_user_id = nil
      self.disabled_invite_reason = nil
      self.save!

      m = Moderation.new
      m.moderator_user_id = mod.id
      m.user_id = self.id
      m.action = "Enabled invitations"
      m.save!
    end

    true
  end

  def undeleted_received_messages
    received_messages.where(:deleted_by_recipient => false).order('id asc')
  end

  def undeleted_sent_messages
    sent_messages.where(:deleted_by_author => false).order('id asc')
  end

  def unread_message_count
    @unread_message_count ||= Keystore.value_for("user:#{self.id}:unread_messages").to_i
  end

  def update_unread_message_count!
    @unread_message_count = self.received_messages.unread.count
    Keystore.put("user:#{self.id}:unread_messages", @unread_message_count)
  end

  def unread_replies_count
    @unread_replies_count ||= ReplyingComment.where(user_id: self.id, is_unread: true).count
  end

  def votes_for_others
    self.votes.left_outer_joins(:story, :comment)
      .where("(votes.comment_id is not null and comments.user_id <> votes.user_id) OR " <<
             "(votes.comment_id is null and stories.user_id <> votes.user_id)")
      .order("id DESC")
  end
end
