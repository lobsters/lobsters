# typed: false

FactoryBot.define do
  factory :message do
    association(:recipient, factory: :user)
    association(:author, factory: :user)
    sequence(:subject) { |n| "message subject #{n}" }
    sequence(:body) { |n| "message body #{n} #{"x " * 60}" } # padidng for length
  end
end
