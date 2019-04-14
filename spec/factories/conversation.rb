FactoryBot.define do
  factory :conversation do
    association(:author, factory: :user)
    association(:recipient, factory: :user)
    sequence(:subject) { |n| "Subject #{n}"}

    trait :deleted_by_author do
      deleted_by_author_at { Time.now }
    end

    trait :deleted_by_recipient do
      deleted_by_recipient_at { Time.now }
    end
  end
end
