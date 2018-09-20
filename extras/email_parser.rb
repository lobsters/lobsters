class EmailParser
  attr_reader :sender, :recipient, :email_text, :email

  def initialize(sender, recipient, email_text)
    @sender = sender
    @recipient = recipient
    @email_text = email_text.forcibly_convert_to_utf8

    @email = nil

    begin
      Utils.silence_stream(STDERR) do
        @email = Mail.read_from_string(email_text)
      end
    rescue
    end

    @sending_user = nil
    @parent = nil
    @body = nil
  end

  def user_token
    @recipient.gsub(/^#{Rails.application.shortname}-/, "").gsub(/@.*/, "")
  end

  def been_here?
    !!@email_text.match(/^X-BeenThere: #{Rails.application.shortname}-/i)
  end

  def sending_user
    return @sending_user if @sending_user

    if (user = User.where("mailing_list_mode > 0 AND mailing_list_token = ?", user_token).first) &&
       user.is_active?
      @sending_user = user
      return user
    end
  end

  def parent
    return @parent if @parent

    irt = self.email[:in_reply_to].to_s.gsub(/[^A-Za-z0-9@\.]/, "")

    if (m = irt.match(/^comment\.([^\.]+)\.\d+@/))
      @parent = Comment.where(:short_id => m[1]).first
    elsif (m = irt.match(/^story\.([^\.]+)\.\d+@/))
      @parent = Story.where(:short_id => m[1]).first
    end

    @parent
  end

  def body
    return @body if @body

    @possible_charset = nil

    if self.email.multipart?
      # parts[0] - multipart/alternative
      #  parts[0].parts[0] - text/plain
      #  parts[0].parts[1] - text/html
      if (found = self.email.parts.first.parts.select {|p| p.content_type.match(/text\/plain/i) }
         ).any?
        @body = found.first.body.to_s

        begin
          @possible_charset = parts.first.content_type_parameters["charset"]
        rescue
        end

      # parts[0] - text/plain
      elsif (found = self.email.parts.select {|p| p.content_type.match(/text\/plain/i) }).any?
        @body = found.first.body.to_s

        begin
          @possible_charset = p.first.content_type_parameters["charset"]
        rescue
        end
      end

    # simple one-part
    elsif self.email.content_type.to_s.match(/text\/plain/i)
      @body = self.email.body.to_s

      begin
        @possible_charset = self.email.content_type_parameters["charset"]
      rescue
      end

    elsif !self.email.content_type.to_s.present?
      # no content-type header, assume it's text/plain
      @body = self.email.body.to_s
    end

    # TODO: use @possible_charset, but did previously forcing the entire
    # email_text to utf8 screw this up already?

    # try to remove sig lines
    @body.gsub!(/^-- \n.+\z/m, "")

    # try to strip out attribution line, followed by an optional blank line,
    # and then lines prefixed with >
    @body.gsub!(/^(On|on|at) .*\n\n?(>.*\n)+/, "")

    @body.strip!
  end
end
