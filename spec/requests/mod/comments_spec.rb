require "rails_helper"

describe "Mod::CommentsController", type: :request do
  let(:mod) { create(:user, :moderator) }
  let(:comment) { create(:comment) }

  before { sign_in mod }

  describe "deleting a comment" do
    it "preserves the moderator's upvoted state in the rendered comment" do
      Vote.vote_thusly_on_story_or_comment_for_user_because(
        1, comment.story_id, comment.id, mod.id, ""
      )

      delete "/mod/comments/#{comment.short_id}",
        params: {reason: "moderation reason"}, xhr: true

      expect(response).to have_http_status(:ok)
      expect(Nokogiri::HTML(response.body).at_css(".comment.upvoted")).to be_present
      expect(comment.reload.is_moderated).to be true
      expect(Vote.where(user: mod, comment: comment, vote: 1)).to exist
    end
  end
end
