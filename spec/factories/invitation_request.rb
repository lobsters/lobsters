# typed: false

FactoryBot.define do
  factory :invitation_request do
    name { "pete smith" }
    sequence(:email) { |n| "user-#{n}@example.com" }
    memo { "https://memo.example" }
    ip_address { "1.1.1.1" }
  end
end
