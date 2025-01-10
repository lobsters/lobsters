# typed: false

class InboxMailbox < ApplicationMailbox
  before_processing :required_info

  def process
    c = Comment.new(user: sending_user, comment: mail.decoded, is_from_email: true)
    if parent.is_a?(Comment)
      c.story_id = parent.story_id
      c.parent_comment_id = parent.id
    else
      c.story_id = parent.id
    end

    # If we fail to parse the comment, just throw an exception.
    c.save!
  end

  private

  def required_info
    if mail.decoded == "" || sending_user.nil? || parent.nil?
      # We could email the user about the bounce, but that doesn't seem
      # to align with current behaviour.
      bounced!
    end
  end

  def parent
    return @parent if @parent

    # Emails In-Reply-To formatted like
    # story.<short_id>.<timestamp of story creation>@<app domain>
    # We throw away the timestamp, since we only care about the short ID.
    irt = mail.in_reply_to.to_s.gsub(/[^A-Za-z0-9@\.]/, "")

    if (m = irt.match(/^comment\.([^\.]+)\.\d+@/))
      @parent = Comment.where(short_id: m[1]).first
    elsif (m = irt.match(/^story\.([^\.]+)\.\d+@/))
      @parent = Story.where(short_id: m[1]).first
    end

    @parent
  end

  def user_token
    (mail.to.find { |e| e =~ /^#{Rails.application.shortname}-/ } || "")[/-([^@]*)@/, 1]
  end

  def sending_user
    return @sending_user if @sending_user

    if (user = User.find_by(mailing_list_token: user_token)) &&
        user.is_active?
      @sending_user = user
      user
    end
  end
end
