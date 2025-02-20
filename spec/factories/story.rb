# typed: false

FactoryBot.define do
  factory :story do
    association(:user)
    sequence(:title) { |n| "story title #{n}" }
    sequence(:url) { |n| "http://example.com/#{n}" }
    tags { Tag.where(tag: "placeholder") }

    trait :deleted do
      is_deleted { true }
      editor { user }
    end
  end
end
