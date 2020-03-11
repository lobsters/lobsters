FactoryBot.define do
  factory :domain do
    sequence(:domain) {|n| "example-#{n}.local" }
  end
end
