# typed: false

FactoryBot.define do
  factory :mod_mail_message do
    association :mod_mail
    association :user
    sequence(:message) { |n| "message body #{n} #{"x " * 60}" } # padding for length

    trait :sent_by_mod do
      association :user, :moderator
    end
  end
end
