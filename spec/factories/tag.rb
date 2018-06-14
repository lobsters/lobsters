FactoryBot.define do
  factory :tag do
    sequence(:tag) {|n| "tag-#{n}" }
    sequence(:description) {|n| "tag #{n}" }
  end
end
