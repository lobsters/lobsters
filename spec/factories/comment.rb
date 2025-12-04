# typed: false

FactoryBot.define do
  factory :comment do
    association(:user)
    association(:story)
    sequence(:comment) { |n| "comment text #{n}" }
    score { 1 }
    created_at { Time.current }
  end
end
