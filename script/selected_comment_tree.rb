#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

def summ(comment_text)
  comment_text.gsub(/[\r\n]/, ' ')[0..40]
end

# max_depth_seen = 0

# oldrange = (1 - -0.2) # 1.2
# newrange = (999 - 0) # 999
# newval = (((confidence - -0.2) * 999) / 1.2)

Story.find_each(batch_size: 100) do |story|
  selected_comments = ActiveRecord::Base.connection.exec_query <<~SQL
    with recursive discussion as (
      select
        id,
        parent_comment_id,
        0 as depth,
        cast(id as char(400)) as path,
        created_at,
        score,
        confidence,
        lpad(1000 - floor(((confidence - -0.2) * 999) / 1.2), 3, '0') as ord,
        cast(concat(lpad(1000 - floor(((confidence - -0.2) * 999) / 1.2), 3, '0'), '.', lpad(id, 9, '0')) as char(600)) as ordpath,
        regexp_replace(substring(comment, 1, 41), "[\r\n]", " ") as blurb
        from comments
        where
          story_id = #{story.id} and
          parent_comment_id is null
      union all
      Select
        c.id,
        c.parent_comment_id,
        depth + 1,
        concat(discussion.path, ",", c.id),
        c.created_at,
        c.score,
        c.confidence,
        lpad(1000 - floor(((c.confidence - -0.2) * 999) / 1.2), 3, '0'),
        concat(discussion.ordpath, ",", lpad(1000 - floor(((c.confidence - -0.2) * 999) / 1.2), 3, '0'), '.', lpad(c.id, 9, '0')),
        regexp_replace(substring(comment, 1, 41), "[\r\n]", " ") as blurb
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

__END__
with recursive discussion as (
  select
    id,
    lpad(id, 9, '0') as padid,
    parent_comment_id,
    0 as depth,
    cast(id as char(200)) as path,
    created_at,
    score,
    confidence,
    999 - floor(confidence * 1000) as ord,
    cast(concat((999 - floor(confidence * 1000)), '.', lpad(id, 9, '0')) as char(200)) as ordpath,
    regexp_replace(substring(comment, 1, 40), "[\r\n]", " ") as blurb
    from comments
    where
      story_id = 4 and
      parent_comment_id is null
  union all
  Select
    c.id,
    lpad(c.id, 9, '0') as padid,
    c.parent_comment_id,
    depth + 1,
    concat(discussion.path, ",", c.id),
    c.created_at,
    c.score,
    c.confidence,
    999 - floor(c.confidence * 1000),
    concat(discussion.ordpath, ",", concat((999 - floor(c.confidence * 1000)), ',', lpad(c.id, 9, '0'))),
    regexp_replace(substring(comment, 1, 40), "[\r\n]", " ") as blurb
  from comments c join discussion on c.parent_comment_id = discussion.id
  )
  select * from discussion order by ordpath;
