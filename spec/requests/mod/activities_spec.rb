# typed: false

require "rails_helper"

describe "Mod::ActivitiesController", type: :request do
  let(:mod) { create(:user, :moderator) }

  before { sign_in mod }

  context "#index" do
    it "loads" do
      story = create(:story)
      story.title = "Replaced title"
      story.tags_was = story.tags.to_a
      story.editor = mod
      expect {
        story.save! # generates Moderation and ModActivity
      }.to change { ModActivity.count }.by(1)

      get "/mod"
      expect(response.status).to eq(200)
      expect(response.body).to include("Replaced title")
    end
  end
end
