#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "production"

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

class String
  def quoted_printable(encoded_word = false)
    s = [self].pack("M")

    if encoded_word
      s.split(/\r?\n/).map {|l|
        "=?UTF-8?Q?" + l.gsub(/=*$/, "").gsub('?', '=3F').tr(" ", "_") << "?="
      }.join("\n\t")
    else
      s
    end
  end

  # like ActionView::Helpers::TextHelper but preserve > and indentation when
  # wrapping lines
  def word_wrap(len)
    split("\n").collect do |line|
      if line.length <= len
        line
      elsif (m = line.match(/^(> ?|   +)(.*)/))
        ind = m[1]
        if len - ind.length <= 0
          ind = "    "
        end
        m[2].gsub(/(.{1,#{len - ind.length}})(\s+|$)/, "#{ind}\\1\n").strip
      else
        line.gsub(/(.{1,#{len}})(\s+|$)/, "\\1\n").strip
      end
    end * "\n"
  end
end

def story_subject(story, prefix = "")
  ss = "#{prefix}#{story.title}"

  story.tags.sort_by(&:tag).each do |t|
    ss << " [#{t.tag}]"
  end

  ss.quoted_printable(true)
end

if __FILE__ == $PROGRAM_NAME
  EMAIL_WIDTH = 72
  LAST_STORY_KEY = "mailing:last_story_id".freeze
  LAST_COMMENT_KEY = "mailing:last_comment_id".freeze

  mailing_list_users = User.where("mailing_list_mode > 0").select(&:is_active?)

  last_story_id = (Keystore.value_for(LAST_STORY_KEY) || Story.last.id).to_i

  Story.where("id > ? AND is_expired = ?", last_story_id, false).order(:id).each do |s|
    s.fetch_story_cache!

    if s.story_cache.blank?
      s.fetch_story_cache!
    end

    s.save

    mailing_list_users.each do |u|
      if (s.tags.map(&:id) & u.tag_filters.map(&:tag_id)).any?
        # story has tags this user has filtered out
        next
      end

      if s.is_hidden_by_user?(u)
        # user has hidden this story
        next
      end

      list = "#{Rails.application.shortname}-#{u.mailing_list_token}@#{Rails.application.domain}"

      IO.popen(
        [{}, "/usr/sbin/sendmail", "-i", "-f", "nobody@#{Rails.application.domain}", u.email],
        "w") do |mail|
        mail.puts "From: #{s.user.username} <#{s.user.username}@#{Rails.application.domain}>"
        mail.puts "Reply-To: #{list}"
        mail.puts "To: #{list}"
        mail.puts "X-BeenThere: #{list}"
        mail.puts "List-Id: #{Rails.application.name} <#{list}>"
        mail.puts "List-Unsubscribe: <#{Rails.application.root_url}settings>"
        mail.puts "Precedence: list"
        mail.puts "MIME-Version: 1.0"
        mail.puts "Content-Type: text/plain; charset=\"utf-8\""
        mail.puts "Content-Transfer-Encoding: quoted-printable"
        mail.puts "Message-ID: <#{s.mailing_list_message_id}>"
        mail.puts "Date: " << s.created_at.strftime("%a, %d %b %Y %H:%M:%S %z")
        mail.puts "Subject: " << story_subject(s)
        mail.puts ""

        body = []

        if s.description.present?
          body.push s.description.to_s.word_wrap(EMAIL_WIDTH)
        end

        if s.url.present?
          if s.description.present?
            body.push ""
          end

          body.push "Via: #{s.url}"

          if s.story_cache.present?
            body.push ""
            body.push s.story_cache.to_s.word_wrap(EMAIL_WIDTH)
          end
        end

        body.push ""
        body.push "-- "
        body.push "Vote: #{s.short_id_url}"

        mail.puts body.join("\n").quoted_printable
      end
    end

    last_story_id = s.id
  end

  Keystore.put(LAST_STORY_KEY, last_story_id)

  # repeat for comments

  last_comment_id = (Keystore.value_for(LAST_COMMENT_KEY) ||
    Comment.last.id).to_i

  Comment.where(
    "id > ? AND (is_deleted = ? AND is_moderated = ?)",
    last_comment_id,
    false,
    false
  ).order(:id).each do |c|
    # allow some time for newer comments to be edited before sending them out
    if (Time.current - (c.updated_at || c.created_at)) < 2.minutes
      break
    end

    mailing_list_users.each do |u|
      if u.mailing_list_mode == 2
        # stories only
        next
      end

      if (c.story.tags.map(&:id) & u.tag_filters.map(&:tag_id)).any?
        # story has tags this user has filtered out
        next
      end

      if c.story.is_hidden_by_user?(u)
        # user has hidden this story
        next
      end

      domain = Rails.application.domain
      list = "#{Rails.application.shortname}-#{u.mailing_list_token}@#{Rails.application.domain}"

      IO.popen([{}, "/usr/sbin/sendmail", "-i", "-f", "nobody@#{domain}", u.email], "w") do |mail|
        from = "From: \"#{c.user.username}"
        if c.hat
          from << " (#{c.hat.hat})"
        end
        from << "\" <#{c.user.username}@#{domain}>"
        mail.puts from

        mail.puts "Reply-To: #{list}"
        mail.puts "To: #{list}"
        mail.puts "List-Id: #{Rails.application.name} <#{list}>"
        mail.puts "List-Unsubscribe: <#{Rails.application.root_url}settings>"
        mail.puts "Precedence: list"
        mail.puts "MIME-Version: 1.0"
        mail.puts "Content-Type: text/plain; charset=\"utf-8\""
        mail.puts "Content-Transfer-Encoding: quoted-printable"
        mail.puts "Message-ID: <#{c.mailing_list_message_id}>"

        refs = ["<#{c.story.mailing_list_message_id}>"]

        if c.parent_comment_id
          mail.puts "In-Reply-To: <#{c.parent_comment.mailing_list_message_id}>"

          thread = []
          indent_level = 0
          Comment.where(:thread_id => c.thread_id).arrange_for_user(nil).reverse_each do |cc|
            if indent_level > 0 && cc.indent_level < indent_level
              thread.unshift cc
              indent_level = cc.indent_level
            elsif cc.id == c.id
              indent_level = cc.indent_level
            end
          end

          thread.each do |cc|
            refs.push "<#{cc.mailing_list_message_id}>"
          end
        else
          mail.puts "In-Reply-To: <#{c.story.mailing_list_message_id}>"
        end

        mail.print "References:"
        refs.each do |ref|
          mail.puts " #{ref}"
        end

        mail.puts "Date: " << c.created_at.strftime("%a, %d %b %Y %H:%M:%S %z")
        mail.puts "Subject: " << story_subject(c.story, "Re: ")
        mail.puts ""

        body = []

        # if the comment has hard line breaks at <80, it likely came from an
        # email, so don't re-wrap it at something shorter
        com = c.comment.to_s
        com_lines = com.split("\n")
        if com_lines.length > 1 && com_lines.first.length < 80
          body.push com.word_wrap(80)
        else
          body.push com.word_wrap(EMAIL_WIDTH)
        end

        body.push ""
        body.push "-- "
        body.push "Vote: #{c.short_id_url}"

        mail.puts body.join("\n").quoted_printable
      end
    end

    last_comment_id = c.id
  end

  Keystore.put(LAST_COMMENT_KEY, last_comment_id)
end
