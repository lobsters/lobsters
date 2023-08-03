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
    concat(lpad(char(2 using binary), 2, char(0 using binary)), lpad(char(#{2 ** (5 * 8)    } using binary), 5, char(0 using binary))) as overflow_comment_id
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
# comment id.

res.first.each do |val|
  puts "#{val.inspect} #{val.last.length}"
end
# puts res.first['v'].to_yaml
