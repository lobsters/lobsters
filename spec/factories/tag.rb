# typed: false

FactoryBot.define do
  factory :tag do
    association(:category)
    sequence(:tag) { |n| "tag-#{n}" }
    sequence(:description) { |n| "tag #{n}" }
    permit_by_new_users { true }
  end
end
