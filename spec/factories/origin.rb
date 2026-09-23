# typed: false

FactoryBot.define do
  factory :origin do
    association(:domain)

    sequence(:identifier) { |n| Faker::Internet.unique.username }

    trait(:banned) do
      banned_by_user { association(:user) }
      banned_at { Time.current }
      banned_reason { "some reason" }
    end
  end
end
