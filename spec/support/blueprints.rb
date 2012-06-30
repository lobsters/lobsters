require 'machinist/active_record'

User.blueprint do
  email { "user-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
  username { "username#{sn}" }
end

Story.blueprint do
  user_id { User.make }
  title { "story title #{sn}" }
  url { "http://example.com/#{sn}" }
end

Tag.blueprint do
  tag { "tag-#{sn}" }
  description { "tag #{sn}" }
end
