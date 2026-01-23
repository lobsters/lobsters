# typed: false

FactoryBot.define do
  factory :mod_mail do
    sequence(:subject) { |n| "Urgent Moderation Mail for you #{n}" }
    recipients { [association(:user)] }
  end
end
