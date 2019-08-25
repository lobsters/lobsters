FactoryBot.define do
  factory :invalid_conversation_without_messages, class: Conversation do
    association(:author, factory: :user)
    association(:recipient, factory: :user)
    sequence(:subject) {|n| "Subject #{n}" }

    trait :deleted_by_author do
      deleted_by_author_at { Time.zone.now }
    end

    trait :deleted_by_recipient do
      deleted_by_recipient_at { Time.zone.now }
    end

    factory :conversation do
      transient do
        body { "Hello" }
      end

      after(:create) do |conversation, evaluator|
        create(:message, conversation: conversation, body: evaluator.body)
        conversation.reload
      end
    end
  end
end
