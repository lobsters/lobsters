# typed: false

require "rails_helper"

describe "comments", type: :request do
  let(:author) { create(:user) }
  let(:comment) { create(:comment, user: author) }
  let(:user) { create(:user) }

  describe "upvoting" do
    before { sign_in user }

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

  describe "deleting" do
    before { sign_in author }

    it "works" do
      expect(comment.is_deletable_by_user?(author)).to be true
      post "/comments/#{comment.short_id}/delete"
      comment.reload
      expect(comment.is_deleted).to be true
    end

    it "works even if the comment is flagged" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(
        -1, comment.story_id, comment.id, user.id, "T"
      )
      expect(comment.is_deletable_by_user?(author)).to be true
      post "/comments/#{comment.short_id}/delete"
      comment.reload
      expect(comment.is_deleted).to be true
    end
  end

  describe "rss" do
    it "renders" do
      comment = create(:comment)

      get "/comments.rss"
      expect(response).to be_successful
      expect(response.body).to include(comment.comment[0..20])
      expect(response.body).to include(comment.user.username)
    end
  end

  describe "disowning" do
    let(:inactive_user) { create(:user, :inactive) }

    before do
      sign_in author
      comment.update!(created_at: (Comment::DELETEABLE_DAYS + 1).days.ago)
    end

    it "returns 302 for non-xhr request" do
      expect {
        post "/comments/#{comment.short_id}/disown"
        expect(response.status).to eq(302)
      }.to change { comment.reload.user }.from(comment.user).to(inactive_user)
    end

    it "returns 200 for xhr request" do
      expect {
        post "/comments/#{comment.short_id}/disown", xhr: true
        expect(response.status).to eq(200)
      }.to change { comment.reload.user }.from(comment.user).to(inactive_user)
    end
  end
end
