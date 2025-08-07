# typed: false

FactoryBot.define do
  factory :hat_request do
    association(:user)
    hat { "foobar hat" }
    link { "https://lobste.rs" }
    sequence(:comment) { |n| "comment text #{n} #{"pad " * 10}" }
    created_at { Time.current }
  end
end
