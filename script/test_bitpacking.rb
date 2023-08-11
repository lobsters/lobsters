#!/usr/bin/env ruby

APP_PATH = File.expand_path('../../config/application', __FILE__)
require File.expand_path('../../config/boot', __FILE__)
require APP_PATH
Rails.application.require_environment!

res = ActiveRecord::Base.connection.exec_query <<~SQL
  select
    concat(lpad(char(65 using binary), 2, char(0 using binary)), lpad(char(435431 using binary), 5, char(0 using binary))) as first,
    concat(lpad(char(257 using binary), 2, char(0 using binary)), lpad(char(435431 using binary), 5, char(0 using binary))) as endianness,
    concat(lpad(char(65536 using binary), 2, char(0 using binary)), lpad(char(435431 using binary), 5, char(0 using binary))) as overflow1,
    concat(lpad(char(65537 using binary), 2, char(0 using binary)), lpad(char(435431 using binary), 5, char(0 using binary))) as overflow2,
    concat(lpad(char(1 using binary), 2, char(0 using binary)), lpad(char(#{2 ** (4 * 8)} using binary), 5, char(0 using binary))) as nooverflow,
    concat(lpad(char(1 using binary), 2, char(0 using binary)), lpad(char(#{2 ** (5 * 8) - 1} using binary), 5, char(0 using binary))) as nooverflow2,

    char(#{2 ** 24 - 1} using binary) as int24bit,
    char(#{2 ** 32 - 1} using binary) as int32bit,
    char(#{2 ** 40 - 1} using binary) as int40bit,
    char(#{2 ** 48 - 1} using binary) as int48bit,

    concat(lpad(char(2 using binary), 2, char(0 using binary)), lpad(char(#{2 ** (5 * 8)    } using binary), 5, char(0 using binary))) as overflow_comment_id,

    65 & 0xff as getbyte1,
    255 & 0xff as getbyte2,
    256 & 0xff as getbyte3,
    435431 & 0xff as getbyte4,
    #{2 ** (5 * 8) -1} & 0xff as getbyte5,

    lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0') as ord0,
    lpad(char(65536 - floor(((-0.195 - -0.2) * 65535) / 1.2) using binary), 2, '0') as ordlow,
    lpad(char(65536 - floor(((0.99 - -0.2) * 65535) / 1.2) using binary), 2, '0') as ordhigh,

    cast(concat(lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(98869 & 0xff using binary)) as char(90) character set binary) as base_ordpath,

    cast(concat(lpad("", 3, 0), lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(98869 & 0xff using binary)) as char(90) character set binary) as ordpath_d2_section,

    cast(concat(
      substring(cast(concat(lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(98869 & 0xff using binary)) as char(90) character set binary), 1, 3),
      cast(concat(lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(98869 & 0xff using binary)) as char(3) character set binary)
    ) as char(90) character set binary) as ordpath_d2,

    cast(concat(
      substring(cast(concat(lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'), char(98869 & 0xff using binary)) as char(90) character set binary), 1, 3),
      lpad(char(65536 - floor(((0 - -0.2) * 65535) / 1.2) using binary), 2, '0'),
      char(98869 & 0xff using binary)
    ) as char(90) character set binary) as ordpath_d2_shorter


    ;
SQL

# why are the integers truncated to 4 bytes?? some internal quirk of char() yep, docs:
# > CHAR() interprets each argument as an INT and returns a string consisting of the characters
# > given by the code values of those integers.
# 
# also next sentence says 'using binary' is the default but I'd rather specify my magic.
#
# ...I don't need the whole comment id, just enough unique bits to differentiate siblings w same
# confidence. Instead of comment id, the right side could even be a count of existing replies to
# parent. But then I'd have to subselect on insert w a lock, and collision barely matters.
# How many siblings do comments have?
#
# select count(*) from comments where parent_comment_id is not null group by parent_comment_id order by 1 desc limit 10;
# > 16, 15, 15, 14, 13, 13, 13, 13, 13, 12
# current max is 16 children (15 sibs). but how many confidence collisions?
# select count(*) from comments where parent_comment_id is not null group by parent_comment_id, confidence order by 1 desc limit 10;
# > 11, 8, 8, 8, 7, 7, 7, 7, 6, 6
# So many? Oh, it's all the comments with only author's upvote, or author + one person.
#
# Still, a collision only means two same-confidence comments aren't oldest-first, which is ALREADY
# often the case because arrange_for_user is underspecified. I'll just take the bottom byte of
# comment id. (And heck, there's further only a 50% chance the collision results in flipped order.)
#
# So 2 bytes for confidence and 1 for id. Deepest reply chain is currently 30, so that's 90b.
# TINYBLOB it is.

res.first.each do |val|
  puts "#{val.inspect} #{val.last.length if val.last.is_a? String}"
end
# puts res.first['v'].to_yaml

ActiveRecord::Base.logger = Logger.new STDOUT
ActiveRecord::Base.clear_reloadable_connections!

puts;puts;puts

story_id = 43385
story_ids = Story.where(merged_story_id: story_id).pluck(:id) + [story_id]
q = Comment.where(story_id: story_ids).joins( <<~SQL
  inner join (
    with recursive discussion as (
    select
      c.id,
      0 as depth,
      cast(concat(lpad(1000 - floor(((confidence - -0.2) * 999) / 1.2), 3, '0'), '.', lpad(id, 9, '0')) as char(600)) as ordpath
      from comments c
      where
        story_id in (#{story_ids.join(',')}) and
        parent_comment_id is null
    union all
    select
      c.id,
      discussion.depth + 1,
      concat(discussion.ordpath, ",", lpad(1000 - floor(((c.confidence - -0.2) * 999) / 1.2), 3, '0'), '.', lpad(c.id, 9, '0'))
    from comments c join discussion on c.parent_comment_id = discussion.id
    )
    select * from discussion as comments
  ) as comments_recursive on comments.id = comments_recursive.id
  SQL
                 )
                   .order('comments_recursive.ordpath').select('comments.*, comments_recursive.depth as depth')
                  .includes(:user, :story, :hat, :votes => :user)
# puts q.to_sql
q.each do |c|
  puts "#{' ' * c.depth} #{c.indent_level} #{c.id} #{c.user.username}"
end
