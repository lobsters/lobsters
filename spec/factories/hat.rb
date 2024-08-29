# typed: false

FactoryBot.define do
  factory :hat do
    association(:user)
    sequence(:hat) { |n| Faker::Lorem.sentence(word_count: 2)[..-2] }
    association(:granted_by_user, factory: :user)
    link { "http://example.com" }
  end
end
