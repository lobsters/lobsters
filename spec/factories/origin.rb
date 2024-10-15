# typed: false

FactoryBot.define do
  factory :origin do
    association(:domain)

    sequence(:identifier) { |n| Faker::Internet.unique.username }
  end
end
