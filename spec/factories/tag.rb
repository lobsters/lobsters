FactoryBot.define do
  factory :tag do
    association(:category)
    sequence(:tag) {|n| "tag-#{n}" }
    sequence(:description) {|n| "tag #{n}" }
  end
end
