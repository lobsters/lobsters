FactoryBot.define do
  factory :story do
    association(:user)
    sequence(:title) { |n| "story title #{n}" }
    sequence(:url) { |n| "http://example.com/#{n}" }
    tags { Tag.where(tag: "placeholder") }

    transient do
      create_votes { 0 }
      create_flags { 0 }
    end

    after(:create) do |story, evaluator|
      if evaluator.create_votes > 0 || evaluator.create_flags > 0
        create_list(:vote, evaluator.create_votes, story: story)
        create_list(:vote, evaluator.create_flags, story: story, vote: -1, reason: "S")
        story.update_score_and_recalculate!(evaluator.create_votes - evaluator.create_flags, evaluator.create_flags)
      end
    end

    trait :deleted do
      is_deleted { true }
      editor { user }
    end
  end
end
