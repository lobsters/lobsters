#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

admin = User.find(78)

def summ(comment_text)
  comment_text.gsub(/[\r\n]/, ' ')[0..40]
end

def arranged_comments_tree(comments, depth = 1)
  str = ''

  # lifted from app/views/stories/show.html.erb
  comments_by_parent = comments.group_by(&:parent_comment_id)
  subtree = comments_by_parent[nil]
  ancestors = []

  while subtree
    if (comment = subtree.shift)
      indent = '  ' * depth

      children = comments_by_parent[comment.id]
      # children.sort! {|a, b|
      #   if a.confidence != b.confidence
      #     b.confidence <=> a.confidence
      #   else
      #     a.id <=> b.id
      #   end
      # } if children
      str += indent + "#{comment.id} #{comment.confidence} #{summ(comment.comment)}\n"

      if children
        ancestors << subtree
        subtree = children
        depth += 1
      end
    elsif (subtree = ancestors.pop)
      # subtree.sort! {|a, b|
      #   if a.confidence != b.confidence
      #     b.confidence <=> a.confidence
      #   else
      #     a.id <=> b.id
      #   end
      # }
      depth -= 1
    end
  end

  str
end

Story.find_each(batch_size: 100) do |story|
  arranged_comments = story.merged_comments

  puts "Story #{story.short_id} http://localhost:3000/s/#{story.short_id}"
  print arranged_comments_tree(arranged_comments)

  puts
  puts
end

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
