require 'machinist/active_record'

User.blueprint do
  email { "user-#{sn}@example.com" }
  password { "blah blah" }
  password_confirmation { object.password }
end
