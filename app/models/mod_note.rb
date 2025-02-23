# typed: false

class ModNote < ApplicationRecord
  extend TimeAgoInWords

  belongs_to :moderator,
    class_name: "User",
    foreign_key: "moderator_user_id",
    inverse_of: :moderations
  belongs_to :user,
    inverse_of: :mod_notes

  scope :recent, -> { where("created_at >= ?", 1.week.ago).order(created_at: :desc) }
  scope :for, ->(user) { includes(:moderator).where(user_id: user).order(created_at: :desc) }

  validates :note, :markeddown_note, presence: true, length: {maximum: 65_535}

  delegate :username, to: :user

  def username=(username)
    self.user_id = nil

    if (u = User.find_by(username: username))
      self.user_id = u.id
      @username = u.username
    else
      errors.add(:username, "is not a valid user")
    end
  end

  def note=(n)
    self[:note] = n.to_s.strip
    self.markeddown_note = generated_markeddown
  end

  def generated_markeddown
    Markdowner.to_html(note)
  end

  def self.create_from_message(message, moderator)
    user = (moderator.id == message.recipient.id && message.author) ?
             message.author : message.recipient

    ModNote.create!(
      moderator: moderator,
      user: user,
      created_at: message.created_at,
      note: <<~NOTE
        *#{message.author ? message.author.username : "(System)"} #{message.hat ? message.hat.to_txt : ""}-> #{message.recipient.username}*: #{message.subject}

        #{message.body}
      NOTE
    )
  end

  def self.record_reparent!(reparent_user, mod, reason)
    old_inviter_url = Rails.application.routes.url_helpers.user_url(
      reparent_user.invited_by_user,
      host: Rails.application.domain
    )
    create_without_dupe!(
      moderator: mod,
      user: reparent_user,
      note: "Reparented from [#{reparent_user.invited_by_user.username}](#{old_inviter_url}) to #{mod.username} with reason: #{reason}"
    )

    reparent_user_url = Rails.application.routes.url_helpers.user_url(
      reparent_user,
      host: Rails.application.domain
    )
    create_without_dupe!(
      moderator: mod,
      user: reparent_user.invited_by_user,
      note: "Admin reparented their invitee [#{reparent_user.username}](#{reparent_user_url}) to #{mod.username} with reason: #{reason}"
    )
  end

  def self.tattle_on_banned_login(user)
    # rubocop:disable Rails/SaveBang
    create(
      moderator: InactiveUser.inactive_user,
      user: user,
      note: "Attempted to log in while banned."
    )
    # rubocop:enable Rails/SaveBang
  end

  def self.tattle_on_brigading!(story)
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: story.user,
      created_at: Time.current,
      note: "Attempted to submit a project's bug tracker or discussion:\n" \
        "- user joined: #{how_long_ago(story.user.created_at)}\n" \
        "- url: #{story.url}\n" \
        "- title: #{story.title}\n" \
        "- user_is_author: #{story.user_is_author}\n" \
        "- tags: #{story.tags.map(&:tag).join(" ")}\n" \
        "- description: #{story.description}\n"
    )
  end

  def self.tattle_on_deleted_login(user)
    # rubocop:disable Rails/SaveBang
    create(
      moderator: InactiveUser.inactive_user,
      user: user,
      note: "Attempted to log in after deleting their account."
    )
    # rubocop:enable Rails/SaveBang
  end

  def self.tattle_on_invited(redeemer, invitation_code)
    invitation = Invitation.find_by(code: invitation_code)
    return unless invitation
    invitation.update!(used_at: Time.current, new_user: nil)

    sender = invitation.user
    sender_url = Rails.application.routes.url_helpers.user_url(
      sender,
      host: Rails.application.domain
    )
    redeemer_url = Rails.application.routes.url_helpers.user_url(
      redeemer,
      host: Rails.application.domain
    )
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: redeemer,
      created_at: Time.current,
      note: "Attempted to redeem invitation code #{invitation.code} while logged in:\n" \
        "- sent by: [#{sender.username}](#{sender_url})\n" \
        "- created_at: #{invitation.created_at}\n" \
        "- used_at: #{invitation.used_at || "unused"}\n" \
        "- email: #{invitation.email}\n" \
        "- memo: #{invitation.memo}"
    )
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: sender,
      created_at: Time.current,
      note: "Sent invitation #{invitation.code} another user tried to redeem while logged in:\n" \
        "- attempted redeemer: [#{redeemer.username}](#{redeemer_url})\n" \
        "- created_at: #{invitation.created_at}\n" \
        "- used_at: #{invitation.used_at || "unused"}\n" \
        "- email: #{invitation.email}\n" \
        "- memo: #{invitation.memo}"
    )
  end

  def self.tattle_on_max_depth_limit(user, parent_comment)
    parent_author_url = Rails.application.routes.url_helpers.user_url(
      parent_comment.user,
      host: Rails.application.domain
    )
    comment_url = Rails.application.routes.url_helpers.comment_url(
      parent_comment,
      host: Rails.application.domain
    )
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: user,
      created_at: Time.current,
      note: "Hit max comment depth replying to [#{parent_comment.short_id}](#{comment_url}) " \
        "by [#{parent_comment.user.username}](#{parent_author_url})"
    )
  end

  def self.tattle_on_new_user_tagging!(story)
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: story.user,
      created_at: Time.current,
      note: "Attempted to submit a story with tag(s) not allowed to new users:\n" \
        "- user joined: #{how_long_ago(story.user.created_at)}\n" \
        "- url: #{story.url}\n" \
        "- title: #{story.title}\n" \
        "- user_is_author: #{story.user_is_author}\n" \
        "- tags: #{story.tags.map(&:tag).join(" ")}\n" \
        "- description: #{story.description}\n"
    )
  end

  def self.tattle_on_story_domain!(story, reason)
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: story.user,
      created_at: Time.current,
      note: "Attempted to post a story from a #{reason} domain:\n" \
        "- user joined: #{how_long_ago(story.user.created_at)}\n" \
        "- url: #{story.url}\n" \
        "- title: #{story.title}\n" \
        "- user_is_author: #{story.user_is_author}\n" \
        "- tags: #{story.tags.map(&:tag).join(" ")}\n" \
        "- description: #{story.description}\n"
    )
  end

  def self.tattle_on_story_origin!(story, reason)
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: story.user,
      created_at: Time.current,
      note: "Attempted to post a story from a #{reason} origin:\n" \
        "- user joined: #{how_long_ago(story.user.created_at)}\n" \
        "- url: #{story.url}\n" \
        "- origin: #{story.origin.identifier}\n" \
        "- title: #{story.title}\n" \
        "- user_is_author: #{story.user_is_author}\n" \
        "- tags: #{story.tags.map(&:tag).join(" ")}\n" \
        "- description: #{story.description}\n"
    )
  end

  def self.tattle_on_traffic_attribution!(story)
    create_without_dupe!(
      moderator: InactiveUser.inactive_user,
      user: story.user,
      created_at: Time.current,
      note: "Attempted to submit a URL attributing traffic:\n" \
        "- user joined: #{how_long_ago(story.user.created_at)}\n" \
        "- url: #{story.url}\n" \
        "- title: #{story.title}\n" \
        "- user_is_author: #{story.user_is_author}\n" \
        "- tags: #{story.tags.map(&:tag).join(" ")}\n" \
        "- description: #{story.description}\n"
    )
  end

  # story validations run on preview, check_url_dupe, title fetching
  # and save attempts, leading to duplicate notes
  def self.create_without_dupe!(attrs)
    latest = attrs[:user].mod_notes.last
    return latest if latest && attrs[:moderator] == latest.moderator && attrs[:note] == latest.note
    ModNote.create!(attrs)
  end
end
