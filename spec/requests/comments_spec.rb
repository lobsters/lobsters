# typed: false

require "rails_helper"

describe "comments", type: :request do
  let(:user) { create(:user) }
  let(:comment) { create(:comment) }

  before { sign_in user }

  describe "upvoting" do
    it "works" do
      expect(comment.score).to eq(1)
      expect(comment.reload.score).to eq(1)
      post "/comments/#{comment.short_id}/upvote"
      expect(response.status).to eq(200)
      expect(comment.reload.score).to eq(2)
      expect(Vote.where(user: user).count).to eq(1)
    end

    it "does nothing to deleted comments" do
      comment.delete_for_user(comment.user)
      comment.reload
      expect {
        expect(comment.is_deleted).to be true
        post "/comments/#{comment.short_id}/upvote"
        expect(response.status).to eq(400)
      }.to change { comment.reload.score }.by(0)
      expect(Vote.where(user: user).count).to eq(0)
    end
  end
end
