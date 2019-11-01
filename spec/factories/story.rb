FactoryBot.define do
  factory :story do
    association(:user)
    sequence(:title) {|n| "story title #{n}" }
    sequence(:url) {|n| "http://example.com/#{n}" }
    tags_a { ["tag1", "tag2"] }

    trait :deleted do
      is_expired { true }
      editor { user }
    end
  end
end
