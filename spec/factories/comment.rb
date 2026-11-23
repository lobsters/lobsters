FactoryBot.define do
  factory :comment do
    association(:user)
    association(:story)
    sequence(:comment) { |n| "comment text #{n}" }
    score { 1 }
    created_at { Time.current }

    transient do
      create_votes { 0 }
    end

    after(:create) do |comment, evaluator|
      if evaluator.create_votes > 0
        create_list(:vote, evaluator.create_votes, story: comment.story, comment: comment)
        comment.update_score_and_recalculate!(evaluator.create_votes, 0)
      end
    end
  end
end
