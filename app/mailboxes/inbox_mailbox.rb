# typed: false

class InboxMailbox < ApplicationMailbox
  before_processing :required_info

  def process
    c = Comment.new(user: sending_user, comment: @decoded, is_from_email: true)
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

  def forcibly_convert_to_utf8(string)
    if string.encoding == Encoding::UTF_8 && string.valid_encoding?
      return string
    end

    string.b.encode(
      Encoding::UTF_8,
      invalid: :replace,
      undef: :replace,
      replace: "?"
    )
  end

  def parent
    return @parent if @parent

    # Emails In-Reply-To formatted like
    # story.<short_id>.<timestamp of story creation>@<app domain>
    # We throw away the timestamp, since we only care about the short ID.
    irt = mail.in_reply_to.to_s.gsub(/[^A-Za-z0-9@.]/, "")

    if (m = irt.match(/^comment\.([^.]+)\.\d+@/))
      @parent = Comment.where(short_id: m[1]).first
    elsif (m = irt.match(/^story\.([^.]+)\.\d+@/))
      @parent = Story.where(short_id: m[1]).first
    end

    @parent
  end

  def required_info
    body = if mail.content_type.blank? # old, non-multipart message
      mail.decoded.to_s
    elsif /text\/plain/.match?(mail.content_type.to_s)
      mail.body.to_s
    elsif mail.multipart?
      # parts[0] - multipart/alternative
      #  parts[0].parts[0] - text/plain
      #  parts[0].parts[1] - text/html
      if (found = mail.parts.first.parts.select { |p| p.content_type.match(/text\/plain/i) }
         ).any?
        found.first.body.to_s
      elsif (found = mail.parts.select { |p| p.content_type.match(/text\/plain/i) }).any?
        found.first.body.to_s
      else
        bounced!
      end
    end

    @decoded = tidy(forcibly_convert_to_utf8(body))
    if @decoded == "" || sending_user.nil? || parent.nil?
      # We could email the user about the bounce, but that doesn't seem
      # to align with current behaviour.
      bounced!
    end
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

  def tidy(body)
    body.gsub(/^-- \n.+\z/m, "")                # sig
      .gsub(/^(On|on|at) .*\n\n?(>.*\n)+/m, "") # top-posting
      .strip
  end
end
