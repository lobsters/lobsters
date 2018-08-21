FactoryBot.define do
  factory :hat do
    association(:user)
    sequence(:hat) {|n| "hat #{n}" }
    association(:granted_by_user, factory: :user)
    link { 'http://example.com' }
  end
end
