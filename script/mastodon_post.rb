#!/usr/bin/env ruby

ENV["RAILS_ENV"] ||= "production"

require File.expand_path("../../config/environment", __FILE__)

exit unless Mastodon.enabled? && Rails.application.credentials.mastodon.bot_name

Story.to_mastodon.each_with_index do |s, i|
  if i > 0
    sleep 2
  end

  tags = s.tags.pluck(:tag).map { |t| " #" + t }.join("")

  via = if s.user.mastodon_username.present?
    (s.user_is_author? ? " by" : " via") + " @#{s.user.mastodon_username}@#{s.user.mastodon_instance}"
  else
    " "
  end

  link_status = via + " " +
    ("X" * Mastodon::LINK_LENGTH) + tags +
    (s.url.present? ? "\n" + ("X" * Mastodon::LINK_LENGTH) : "")

  status = via + " " + s.short_id_url + tags +
    (s.url.present? ? "\n" + s.url : "")

  left_len = Mastodon::MAX_STATUS_LENGTH - link_status.length

  title = s.title

  # if there are any urls in the title, they should be sized (at least) to a url
  left_len -= title.scan(/[^ ]\.[a-z]{2,10}/i)
    .map { |_u| [0, Mastodon::LINK_LENGTH].max }
    .inject(:+)
    .to_i

  if left_len < -3
    left_len = -3
  end

  status = if title.bytesize > left_len
    title[0, left_len - 3] + "..." + status
  else
    title + status
  end

  begin
    res = Mastodon.post(status)
    post = JSON.parse(res.body)
    s.update_column(:mastodon_id, post["id"])
  rescue => e
    s.update_column(:mastodon_id, 0)
    puts "failed posting story #{s.id} (#{status.inspect}): #{e.inspect}\n#{res.inspect}"
    exit
  end
end
