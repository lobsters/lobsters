# typed: false

FactoryBot.define do
  factory :domain do
    sequence(:domain) { |n| Faker::Internet.domain_name }

    trait(:banned) do
      banned_by_user { association(:user) }
      banned_at { Time.current }
      banned_reason { "some reason" }
    end
  end
end
