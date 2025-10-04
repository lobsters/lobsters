# typed: false

require "rails_helper"

describe CommentsController do
  include ActiveJob::TestHelper

  after do
    clear_enqueued_jobs
  end

  let(:author) { create(:user) }
  let(:story) { create(:story, user: author) }
  let(:reader) { create(:user) }

  describe "POST create" do
    it "schedules a notification job" do
      stub_login_as reader
      post :create, params: {story_id: story.short_id, comment: "great story!"}
      expect(response.status).to eq(302)
      expect(NotifyCommentJob).to have_been_enqueued.exactly(:once)
    end
  end
end
