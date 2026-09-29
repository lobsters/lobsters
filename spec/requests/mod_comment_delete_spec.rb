# typed: false

require "rails_helper"

# Regression test for #2201: a moderator deleting a comment rendered the
# comment partial without the moderator's own vote state, so the upvote arrow
# came back empty until the page was reloaded (a reload goes through
# CommentsController, which does load `current_vote`).
describe "mod comment deletion", type: :request do
  let(:author) { create(:user) }
  let(:story) { create(:story, user: author) }
  let(:moderator) { create(:user, :moderator) }
  let(:comment) { create(:comment, story: story, user: author) }

  it "renders the deleted comment with the moderator's vote state loaded" do
    create(:vote, story: story, comment: comment, user: moderator, vote: 1)
    sign_in moderator

    delete "/mod/comments/#{comment.short_id}", xhr: true

    expect(response).to have_http_status(200)
    # `upvoted` is the class the partial puts on the voter's own comment only
    # when Comment#current_upvoted? is true, which needs current_vote loaded.
    expect(response.body).to include("upvoted")
  end
end
