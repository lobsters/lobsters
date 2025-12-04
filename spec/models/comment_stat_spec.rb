# typed: false

require "rails_helper"

RSpec.describe CommentStat, type: :model do
  it "creates daily stats idempotently" do
    comment = create :comment, created_at: 8.hours.ago

    expect {
      CommentStat.daily_fill!
      CommentStat.daily_fill!
    }.to change { CommentStat.count }.by(1)
  end
end
