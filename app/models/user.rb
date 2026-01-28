# typed: false

class User < ApplicationRecord
  has_many :stories, -> { includes :user }, inverse_of: :user
  has_many :comments,
    inverse_of: :user,
    dependent: :restrict_with_exception
  has_many :sent_messages,
    class_name: "Message",
    foreign_key: "author_user_id",
    inverse_of: :author,
    dependent: :restrict_with_exception
  has_many :received_messages,
    class_name: "Message",
    foreign_key: "recipient_user_id",
    inverse_of: :recipient,
    dependent: :restrict_with_exception
  has_many :tag_filters, dependent: :destroy
  has_many :tag_filter_tags,
    class_name: "Tag",
    through: :tag_filters,
    source: :tag,
    dependent: :delete_all
  belongs_to :invited_by_user,
    class_name: "User",
    inverse_of: false,
    optional: true
  belongs_to :banned_by_user,
    class_name: "User",
    inverse_of: false,
    optional: true
  belongs_to :disabled_invite_by_user,
    class_name: "User",
    inverse_of: false,
    optional: true
  has_many :invitations, dependent: :destroy
  has_many :mod_notes,
    inverse_of: :user,
    dependent: :restrict_with_exception
  has_many :moderations,
    inverse_of: :moderator,
    dependent: :restrict_with_exception
  has_one :moderation,
    inverse_of: :user,
    dependent: :restrict_with_exception
  has_many :usernames, dependent: :destroy
  has_many :votes, dependent: :destroy
  has_many :voted_stories, -> { where("votes.comment_id" => nil) },
    through: :votes,
    source: :story
  has_many :upvoted_stories,
    -> {
      where("votes.comment_id" => nil, "votes.vote" => 1)
        .where("stories.user_id != votes.user_id")
    },
    through: :votes,
    source: :story
  has_many :hats, dependent: :destroy
  has_many :wearable_hats, -> { where(doffed_at: nil) },
    class_name: "Hat",
    inverse_of: :user
  has_many :hat_requests, dependent: :restrict_with_exception
  has_many :notifications, dependent: :restrict_with_exception
  has_many :hidings,
    class_name: "HiddenStory",
    inverse_of: :user,
    dependent: :destroy
  has_many :read_ribbons, dependent: :restrict_with_exception
  has_many :saved_stories, dependent: :restrict_with_exception
  has_many :suggested_taggings, dependent: :restrict_with_exception
  has_many :suggested_titles, dependent: :restrict_with_exception
  has_many :mod_mail_recipients, dependent: :restrict_with_exception
  has_many :mod_mail_messages, dependent: :restrict_with_exception

  include EmailBlocklistValidation
  include Token
  include UsernameAttribute

  # As of Rails 8.0, `has_secure_password` generates a `password_reset_token`
  # method that shadows the explicit `password_reset_token` attribute.
  # So we need to explictily disable that.
  has_secure_password(reset_token: false)

  typed_store :settings do |s|
    s.string :prefers_color_scheme, default: "system"
    s.string :prefers_contrast, default: "system"
    s.boolean :email_notifications, default: false
    s.boolean :email_replies, default: false
    s.boolean :pushover_replies, default: false
    s.string :pushover_user_key
    s.boolean :email_messages, default: false
    s.boolean :pushover_messages, default: false
    s.boolean :email_mentions, default: false
    s.boolean :inbox_mentions, default: true
    s.boolean :show_avatars, default: true
    s.boolean :show_email, default: false
    s.boolean :show_story_previews, default: false
    s.boolean :show_submitted_story_threads, default: false
    s.string :totp_secret
    s.string :github_oauth_token
    s.string :github_username
    s.string :mastodon_instance
    s.string :mastodon_oauth_token
    s.string :mastodon_username
    s.string :homepage
  end

  validates :prefers_color_scheme, inclusion: %w[system light dark]
  validates :prefers_contrast, inclusion: %w[system normal high]

  validates :username, uniqueness: {case_sensitive: false}
  validates :email,
    length: {maximum: 100},
    format: {with: /\A[^@ ]+@[^@ ]+\.[^@ ]+\Z/},
    uniqueness: {case_sensitive: false}
  validate :validate_username_timeouts

  validates :homepage,
    format: {
      with: /\A(?:https?|gemini|gopher):\/\/[^\/\s]+\.[^.\/\s]+(\/.*)?\Z/
    },
    allow_blank: true

  validates :password, presence: true, on: :create
  validates :password_digest, length: {maximum: 75}

  validates :password_reset_token,
    uniqueness: {case_sensitive: false},
    length: {maximum: 75},
    allow_blank: true # because the column does not have a non-null constraint
  validates :session_token,
    allow_blank: true,
    presence: true,
    uniqueness: {case_sensitive: false},
    length: {maximum: 75}
  validates :about,
    length: {maximum: 16_777_215}
  validates :rss_token,
    uniqueness: {case_sensitive: false},
    length: {maximum: 75}
  validates :mailing_list_token,
    uniqueness: {case_sensitive: false},
    length: {maximum: 75}
  validates :banned_reason,
    length: {maximum: 255}
  validates :disabled_invite_reason,
    length: {maximum: 200}

  validates :show_email, :is_admin, :is_moderator, :pushover_mentions,
    inclusion: {in: [true, false]}

  validates :karma,
    presence: true

  validates :settings,
    length: {maximum: 16_777_215}

  scope :active, -> { where(banned_at: nil, deleted_at: nil) }
  scope :moderators, -> {
    where("
      is_moderator = True OR
      users.id IN (select distinct moderator_user_id from moderations where token not in (?))
    ", Moderation::BAD_DOFFING_ENTRIES)
  }

  before_save :check_session_token
  before_validation on: :create do
    create_rss_token
    create_mailing_list_token
  end
  after_create do
    Username.create!({username:, user: self, created_at:})
  end

  # days old accounts are considered new for
  NEW_USER_DAYS = 70

  # minimum karma required to be able to offer title/tag suggestions
  MIN_KARMA_TO_SUGGEST = 10

  # minimum karma required to be able to flag comments
  MIN_KARMA_TO_FLAG = 50

  # minimum karma required to be able to submit new stories
  MIN_KARMA_TO_SUBMIT_STORIES = -4

  # minimum karma required to process invitation requests
  MIN_KARMA_FOR_INVITATION_REQUESTS = MIN_KARMA_TO_FLAG

  # proportion of posts authored by user to consider as heavy self promoter
  HEAVY_SELF_PROMOTER_PROPORTION = 0.51

  # minimum number of submitted stories before checking self promotion
  MIN_STORIES_CHECK_SELF_PROMOTION = 2

  def self./(username)
    find_by! username:
  end

  def as_json(_options = {})
    attrs = [
      :username,
      :created_at,
      :is_admin,
      :is_moderator
    ]

    if !is_admin?
      attrs.push :karma
    end

    attrs.push :homepage

    h = super(only: attrs)

    h[:about] = linkified_about
    h[:avatar_url] = avatar_url
    h[:invited_by_user] = User.where(id: invited_by_user_id).pick(:username)

    if github_username.present?
      h[:github_username] = github_username
    end

    if mastodon_username.present?
      h[:mastodon_username] = mastodon_username
    end

    h
  end

  def authenticate_totp(code)
    totp = ROTP::TOTP.new(totp_secret)
    totp.verify(code)
  end

  def avatar_path(size = 100)
    ActionController::Base.helpers.image_path(
      "/avatars/#{username}-#{size}.png",
      skip_pipeline: true
    )
  end

  def avatar_url(size = 100)
    ActionController::Base.helpers.image_url(
      "/avatars/#{username}-#{size}.png",
      skip_pipeline: true
    )
  end

  def disable_invite_by_user_for_reason!(disabler, reason)
    User.transaction do
      self.disabled_invite_at = Time.current
      self.disabled_invite_by_user_id = disabler.id
      self.disabled_invite_reason = reason
      save!

      msg = Message.new
      msg.deleted_by_author = true
      msg.author_user_id = disabler.id
      msg.recipient_user_id = id
      msg.subject = "Your invite privileges have been revoked"
      msg.body = "The reason given:\n" \
        "\n" \
        "> *#{reason}*\n" \
        "\n" \
        "*This is an automated message.*"
      msg.save!

      m = Moderation.new
      m.moderator_user_id = disabler.id
      m.user_id = id
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

      BanNotificationMailer.notify(self, banner, reason).deliver_now unless deleted_at?
      delete!

      m = Moderation.new
      m.moderator_user_id = banner.id
      m.user_id = id
      m.action = "Banned"
      m.reason = reason
      m.save!
    end

    true
  end

  def banned_from_inviting?
    disabled_invite_at?
  end

  def can_flag?(obj)
    if is_new?
      return false
    elsif obj.is_a?(Story)
      if obj.is_flaggable?
        return true
      elsif obj.current_flagged?
        # user can unvote
        return true
      end
    elsif obj.is_a?(Comment) && obj.is_flaggable?
      return karma >= MIN_KARMA_TO_FLAG
    end

    false
  end

  def can_invite?
    !banned_from_inviting? && can_submit_stories?
  end

  def can_offer_suggestions?
    !is_new? && (karma >= MIN_KARMA_TO_SUGGEST)
  end

  def can_see_invitation_requests?
    can_invite? && (is_moderator? ||
      (karma >= MIN_KARMA_FOR_INVITATION_REQUESTS))
  end

  def can_submit_stories?
    karma >= MIN_KARMA_TO_SUBMIT_STORIES
  end

  def check_session_token
    if session_token.blank?
      roll_session_token
    end
  end

  def create_mailing_list_token
    if mailing_list_token.blank?
      self.mailing_list_token = Utils.random_str(10)
    end
  end

  def create_rss_token
    if rss_token.blank?
      self.rss_token = Utils.random_str(60)
    end
  end

  def comments_posted_count
    Keystore.value_for("user:#{id}:comments_posted").to_i
  end

  def comments_deleted_count
    Keystore.value_for("user:#{id}:comments_deleted").to_i
  end

  def fetched_avatar(size = 100)
    gravatar_url = "https://www.gravatar.com/avatar/" <<
      Digest::MD5.hexdigest(email.strip.downcase) <<
      "?r=pg&d=identicon&s=#{size}"

    begin
      s = Sponge.new
      s.timeout = 3
      res = s.fetch(gravatar_url).body
      if res.present?
        return res
      end
    rescue => e
      # Rails.logger.error "error fetching #{gravatar_url}: #{e.message}"
    end

    nil
  end

  def refresh_counts!
    Keystore.put("user:#{id}:stories_submitted", stories.count)
    Keystore.put("user:#{id}:comments_posted", comments.active.count)
    Keystore.put("user:#{id}:comments_deleted", comments.deleted.count)
  end

  def delete!
    User.transaction do
      # walks comments -> story -> merged stories; this is a rare event and likely
      # to be fixed in a redesign of the story merging db model:
      # https://github.com/lobsters/lobsters/issues/1298#issuecomment-2272179720
      comments
        .where("score < 0")
        .find_each { |c| c.delete_for_user(self) }

      # delete messages bypassing validation because a message may have a hat
      # sender has doffed, which would fail validations
      sent_messages.update_all(deleted_by_author: true)
      received_messages.update_all(deleted_by_recipient: true)

      invitations.unused.update_all(used_at: Time.now.utc)
      wearable_hats.where(modlog_use: true).update_all(doffed_at: Time.current)

      roll_session_token

      self.deleted_at = Time.current
      good_riddance?
      save!
    end
  end

  def undelete!
    User.transaction do
      self.deleted_at = nil
      save!
    end
  end

  def disable_2fa!
    self.totp_secret = nil
    save!
  end

  # ensures some users talk to a mod before reactivating
  def good_riddance?
    return if is_banned? # https://www.youtube.com/watch?v=UcZzlPGnKdU

    recent_comments_count = comments
      .where(created_at: 30.days.ago..)
      .where(is_deleted: true).count

    recent_stories_count = stories
      .where(created_at: 30.days.ago..)
      .where(is_deleted: true, is_moderated: true).count

    total_count = recent_comments_count + recent_stories_count

    self.email = "#{username}@lobsters.example" if
      karma < 0 || total_count > 3 ||
        FlaggedCommenters.new("90d").check_list_for(self)
  end

  def grant_moderatorship_by_user!(user)
    User.transaction do
      self.is_moderator = true
      save!

      m = Moderation.new
      m.moderator_user_id = user.id
      m.user_id = id
      m.action = "Granted moderator status"
      m.save!

      h = Hat.new
      h.user_id = id
      h.granted_by_user_id = user.id
      h.hat = "Sysop"
      h.save!
    end

    true
  end

  def initiate_password_reset_for_ip(ip)
    self.password_reset_token = "#{Time.current.to_i}-#{Utils.random_str(30)}"
    save!

    PasswordResetMailer.password_reset_link(self, ip).deliver_now
  end

  def has_2fa?
    totp_secret.present?
  end

  def is_active?
    !(deleted_at? || is_banned?)
  end

  def is_banned?
    banned_at?
  end

  # user was deleted/banned before a server move, see lib/tasks/privacy_wipe
  def is_wiped?
    password_digest == "*"
  end

  def is_new?
    return true unless created_at # unsaved object; in signup flow or a test
    created_at > NEW_USER_DAYS.days.ago
  end

  def ids_replied_to(comment_ids)
    h = Hash.new { false }
    comments
      .where(parent_comment_id: comment_ids)
      .pluck(:parent_comment_id)
      .each do
        h[it] = true
      end
    h
  end

  def roll_session_token
    self.session_token = Utils.random_str(60)
  end

  def is_heavy_self_promoter?
    total_count = stories_submitted_count

    if total_count < MIN_STORIES_CHECK_SELF_PROMOTION
      false
    else
      authored = stories.where(user_is_author: true).count
      authored.to_f / total_count >= HEAVY_SELF_PROMOTER_PROPORTION
    end
  end

  def linkified_about
    Markdowner.to_html(about)
  end

  def mastodon_acct
    raise unless mastodon_username.present? && mastodon_instance.present?
    "@#{mastodon_username}@#{mastodon_instance}"
  end

  def most_common_story_tag
    Tag.active.joins(
      :stories
    ).where(
      stories: {user_id: id, is_deleted: false}
    ).group(
      Tag.arel_table[:id]
    ).order(
      Arel.sql("COUNT(*) desc")
    ).first
  end

  def pushover!(params)
    if pushover_user_key.present?
      Pushover.push(pushover_user_key, params)
    end
  end

  def recent_threads(amount, include_submitted_stories: false, for_user: user)
    # Safe to use accessible_to_user even though ~user/threads is a threaded display because the
    # entire thread disppears from their page.
    comments = self.comments.accessible_to_user(for_user)

    thread_ids = comments.group(:thread_id).order("MAX(created_at) DESC").limit(amount)
      .pluck(:thread_id)

    if include_submitted_stories && show_submitted_story_threads
      thread_ids += Comment.joins(:story)
        .where(stories: {user_id: id}).group(:thread_id)
        .order("MAX(comments.created_at) DESC").limit(amount).pluck(:thread_id)

      thread_ids = thread_ids.uniq.sort.reverse[0, amount]
    end

    thread_ids
  end

  def stories_submitted_count
    Keystore.value_for("user:#{id}:stories_submitted").to_i
  end

  def stories_deleted_count
    Keystore.value_for("user:#{id}:stories_deleted").to_i
  end

  def to_param
    username
  end

  def unban_by_user!(unbanner, reason)
    self.banned_at = nil
    self.banned_by_user_id = nil
    self.banned_reason = nil
    self.deleted_at = nil
    save!

    m = Moderation.new
    m.moderator_user_id = unbanner.id
    m.user_id = id
    m.action = "Unbanned"
    m.reason = reason
    m.save!

    true
  end

  def enable_invite_by_user!(mod)
    User.transaction do
      self.disabled_invite_at = nil
      self.disabled_invite_by_user_id = nil
      self.disabled_invite_reason = nil
      save!

      m = Moderation.new
      m.moderator_user_id = mod.id
      m.user_id = id
      m.action = "Enabled invitations"
      m.save!
    end

    true
  end

  def inbox_count
    @inbox_count ||= notifications.where(read_at: nil).count
  end

  def validate_username_timeouts
    return unless username_changed?

    at = usernames.where("created_at <= ?", 1.year.ago).order(created_at: :desc).first&.created_at
    errors.add(:username, "has already been changed in the last year (#{at.strftime("%Y-%m-%d")})") if at

    recently_used = Username.where(username: username).where("renamed_away_at >= ?", 5.years.ago).order(renamed_away_at: :desc).first&.renamed_away_at
    errors.add(:username, "has been used in the last 5 years (#{recently_used.strftime("%Y-%m-%d")})") if recently_used
  end

  def votes_for_others
    votes
      .left_outer_joins(:story, :comment)
      .includes(comment: :user, story: :user)
      .where("(votes.comment_id is not null and comments.user_id <> votes.user_id) OR " \
                 "(votes.comment_id is null and stories.user_id <> votes.user_id)")
      .order(id: :desc)
  end
end
