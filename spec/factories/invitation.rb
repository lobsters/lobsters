FactoryBot.define do
  factory :invitation do
    association(:user)
    sequence(:email) {|n| "user-#{n}@example.com" }
    memo { 'some text for memo' }
  end
end
