# typed: false

FactoryBot.define do
  factory :message do
    association(:recipient, factory: :user)
    association(:author, factory: :user)
    sequence(:subject) { |n| "message subject #{n}" }
    sequence(:body) { |n| "message body #{n}" }

    has_been_read { false }
  end
end
