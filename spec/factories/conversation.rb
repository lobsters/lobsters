FactoryBot.define do
  factory :conversation do
    association(:author, factory: :user)
    association(:recipient, factory: :user)
  end
end
