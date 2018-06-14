require 'machinist/active_record'

User.blueprint do
  email { "user-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
  username { "username#{sn}" }
  is_moderator { false }
  is_admin { false }
end

User.blueprint(:banned) do
  email { "banned-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
  username { "username#{sn}" }
  banned_at { Time.current }
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
  tags_a { ["tag1", "tag2"] }
end

Hat.blueprint do
  user_id { User.make!.id }
  hat { "hat #{rand}" }
  granted_by_user_id { User.make!.id }
  link { 'http://example.com' }
end

Comment.blueprint do
  user_id { User.make!.id }
  story_id { Story.make!.id }
  comment { "comment text #{sn}" }
  hat { nil }
  created_at { Time.current }
end

Message.blueprint do
  recipient_user_id { User.make!.id }
  author_user_id { User.make!.id }
  subject { "message subject #{sn}" }
  body { "message body #{sn}" }
  hat { nil }
end

Vote.blueprint do
  story
  user
  vote { 1 }
end
