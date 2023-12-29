#!/usr/bin/env ruby

APP_PATH = File.expand_path("../../config/application", __FILE__)
require File.expand_path("../../config/boot", __FILE__)
require APP_PATH
Rails.application.require_environment!

class String
  def quoted_printable(encoded_word = false)
    string = [self].pack("M")

    return string unless encoded_word

    q_encode_word = ->(w) { "=?UTF-8?Q?#{w}?=" }

    string
      # Undo linebreaks from #pack("M") because we'll be adding characters
      .gsub("=\n", "")
      # Question marks are delimiters in q-encoding so must be escaped
      .gsub("?", "=3F")
      # Spaces are insignificant in q-encoding so must be escaped
      .gsub(/\s+/, " _")
      # Take each space-separated word, then q-encode
      .split(" ").map(&q_encode_word)
      # Recombine words then word wrap at 75 characters
      .join(" ").word_wrap(75)
      # Compose final string, folding headers per rfc 2822 section 2.2.3
      .lines.join("\t")
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

  last_story_id = (Keystore.value_for(LAST_STORY_KEY) || Story.last && Story.last.id).to_i

  # Paranoia: only search back three days so that if last_story_id is oddly low we don't start
  # sending every story from the beginning of time, or if mailing list mode breaks for more than a
  # few days we won't bury them in email.
  Story
    .where("id > ? AND is_deleted = ? AND created_at >= ?", last_story_id, false, 3.days.ago)
    .order(:id)
    .each do |s|
    StoryText.fill_cache!(s)

    mailing_list_users.each do |u|
      if (s.tags.map(&:id) & u.tag_filters.map(&:tag_id)).any?
        # story has tags this user has filtered out
        next
      end
    
      if s.is_hidden_by_user?(u)
        # user has hidden this story
        next
      end
    
      body = []
    
      if s.description.present?
        body.push s.description.to_s.word_wrap(EMAIL_WIDTH)
      end
    
      if s.url.present?
        body.push "" if s.description.present?
        body.push "Via: #{s.url}"
    
        StoryText.cached?(s) do |text|
          body.push ""
          body.push text.to_s.word_wrap(EMAIL_WIDTH)
        end
      end
    
      body.push ""
      body.push "-- "
      body.push "Vote: #{s.short_id_url}"
    
      # Send email using ActionMailer
      MailingListMailer.story_email(u, s, body.join("\n").quoted_printable).deliver_now
    end

    last_story_id = s.id
  end

  Keystore.put(LAST_STORY_KEY, last_story_id)

  # repeat for comments

  last_comment_id = (Keystore.value_for(LAST_COMMENT_KEY) || Comment.last && Comment.last.id).to_i

  # Paranoia: only search back three days so that if last_comment_id is oddly low we don't start
  # sending every comment from the beginning of time, or if mailing list mode breaks for more than a
  # few days we won't bury them in email.
  Comment.where(
    "id > ? AND (is_deleted = ? AND is_moderated = ?) AND created_at >= ?",
    last_comment_id,
    false,
    false,
    3.days.ago
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
    
      # Construct email body
      body = []
    
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
    
      # Send email using ActionMailer
      MailingListMailer.comment_email(u, c, c.story, body.join("\n").quoted_printable).deliver_now
    end

    last_comment_id = c.id
  end

  Keystore.put(LAST_COMMENT_KEY, last_comment_id)
end
