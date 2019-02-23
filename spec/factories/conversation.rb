FactoryBot.define do
  factory :conversation do
    association(:author, factory: :user)
    association(:recipient, factory: :user)
    sequence(:subject) { |n| "Subject #{n}"}
  end
end
