require 'machinist/active_record'

User.blueprint do
  email { "user-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
  username { "username#{sn}" }
end

User.blueprint(:banned) do
  email { "banned-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
  username { "username#{sn}" }
  banned_at { Time.now }
end

Tag.blueprint do
  tag { "tag-#{sn}" }
  description { "tag #{sn}" }
end

# these need to exist for stories to use them
Tag.destroy_all
Tag.make!(:tag => "tag1")
Tag.make!(:tag => "tag2")

Story.blueprint do
  user_id { User.make!.id }
  title { "story title #{sn}" }
  url { "http://example.com/#{sn}" }
  tags_a { [ "tag1", "tag2" ] }
end

Comment.blueprint do
  user_id { User.make!.id }
  story_id { Story.make!.id }
  comment { "comment text #{sn}" }
end

Message.blueprint do
  recipient_user_id { User.make!.id }
  author_user_id { User.make!.id }
  subject { "message subject #{sn}" }
  body { "message body #{sn}" }
end

Vote.blueprint do
  story
  user
  vote { 1 }
end
