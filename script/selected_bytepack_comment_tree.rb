#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

def summ(comment_text)
  comment_text.gsub(/[\r\n]/, ' ')[0..40]
end

# max_depth_seen = 0

Story.find_each(batch_size: 100) do |story|
  selected_comments = ActiveRecord::Base.connection.exec_query <<~SQL
    with recursive discussion as (
      select
        c.id,
        c.parent_comment_id,
        0 as depth,
        cast(c.id as char(400)) as path,
        c.created_at,
        c.score,
        c.confidence,
        lpad(char(65536 - floor(((c.confidence - -0.2) * 65535) / 1.2) using binary), 2, '0') as ord,
        cast(null as char(90) character set binary) as parentord,
        cast(concat(lpad(char(65536 - floor(((c.confidence - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(c.id & 0xff using binary)) as char(90) character set binary) as ordpath,
        regexp_replace(substring(c.comment, 1, 41), "[\r\n]", " ") as blurb
        from comments c
        where
          c.story_id = #{story.id} and
          c.parent_comment_id is null
      union all
      select
        c.id,
        c.parent_comment_id,
        depth + 1,
        concat(discussion.path, ",", c.id),
        c.created_at,
        c.score,
        c.confidence,
        lpad(char(65536 - floor(((c.confidence - -0.2) * 65535) / 1.2) using binary), 2, '0'),
        left(discussion.ordpath, 3 * (depth + 1)),
        cast(concat(
          left(discussion.ordpath, 3 * (depth + 1)),
          lpad(char(65536 - floor(((c.confidence - -0.2) * 65535) / 1.2) using binary), 2, '0'),
          char(c.id & 0xff using binary)
        ) as char(90) character set binary),
        regexp_replace(substring(c.comment, 1, 41), "[\r\n]", " ") as blurb
      from comments c join discussion on c.parent_comment_id = discussion.id
      )
      select * from discussion order by ordpath;
  SQL

  puts "Story #{story.short_id} http://localhost:3000/s/#{story.short_id}"
  selected_comments.each do |c|
    puts ('  ' * (c['depth'] + 1)) + "#{c['id']} #{c['confidence']} " + summ(c['blurb'])
    # max_depth_seen = c['depth'] if c['depth'] > max_depth_seen
  end

  puts
  puts
end
# puts "max_depth_seen #{max_depth_seen}"
