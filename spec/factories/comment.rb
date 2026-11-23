FactoryBot.define do
  factory :comment do
    association(:user)
    association(:story)
    sequence(:comment) { |n| "comment text #{n}" }
    score { 1 }
    created_at { Time.current }

    transient do
      create_votes { 0 }
      create_flags { 0 }
    end

    after(:create) do |comment, evaluator|
      if evaluator.create_votes > 0 || evaluator.create_flags > 0
        create_list(:vote, evaluator.create_votes, story: comment.story, comment: comment)
        create_list(:vote, evaluator.create_flags, story: comment.story, comment: comment, vote: -1, reason: "T")
        comment.update_score_and_recalculate!(evaluator.create_votes, evaluator.create_flags)
      end
    end
  end
end
