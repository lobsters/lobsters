FactoryBot.define do
  factory :message do
    association(:conversation)
    association(:recipient, factory: :user)
    association(:author, factory: :user)
    sequence(:subject) {|n| "message subject #{n}" }
    sequence(:body) {|n| "message body #{n}" }

    trait :unread do
      has_been_read { false }
    end
  end
end
