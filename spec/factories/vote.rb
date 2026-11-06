FactoryBot.define do
  factory :vote do
    association(:user)
    vote { 1 }
  end
end
