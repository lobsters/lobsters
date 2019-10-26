FactoryBot.define do
  factory :hat_request do
    association(:user)
    hat { "foobar hat" }
    link { "https://lobste.rs" }
    sequence(:comment) {|n| "comment text #{n}" }
    created_at { Time.current }
  end
end
