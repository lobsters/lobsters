require "rails_helper"

RSpec.describe "moderations", type: :request do
  describe "#index" do
    let(:domain) { create :domain }

    context "with fewer entries than two pages" do
      it "shows the first page", :aggregate_failures do
        Moderation.create!(domain: domain, action: "Unbanned domain")
        get "/moderations"

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).not_to include("Page 2")
      end
    end

    context "with more entries" do
      it "shows the page ignoring extra params", :aggregate_failures do
        # Ensure we end up with two pages of results
        (ModerationsController::ENTRIES_PER_PAGE * 2).times do
          Moderation.create!(domain: domain, action: "Banned domain")
        end

        get "/moderations"

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).to include("Page 2")
      end
    end

    context "when filtering entries by moderator" do
      let!(:story) { create(:story) }
      let!(:moderator1) { create(:user, :moderator, username: "alice") }
      let!(:moderator2) { create(:user, :moderator, username: "bob") }
      let!(:moderation1) { Moderation.create!(story: story, action: "Alice Moderation", moderator: moderator1) }
      let!(:moderation2) { Moderation.create!(story: story, action: "Bob Moderation", moderator: moderator2) }
      let!(:moderation3) { Moderation.create!(story: story, action: "Changed tags", is_from_suggestions: true) }

      it "shows all by default" do
        get "/moderations"

        expect(response).to be_successful
        expect(response.body).to include("Alice Moderation")
        expect(response.body).to include("Bob Moderation")
        expect(response.body).to include("Changed tags")
      end

      it "shows all when selected" do
        get "/moderations", params: {moderator: "(All)"}

        expect(response).to be_successful
        expect(response.body).to include("Alice Moderation")
        expect(response.body).to include("Bob Moderation")
        expect(response.body).to include("Changed tags")
      end

      it "shows all moderator actions when selected" do
        get "/moderations", params: {moderator: "(Moderators)"}

        expect(response).to be_successful
        expect(response.body).to include("Alice Moderation")
        expect(response.body).to include("Bob Moderation")
        expect(response.body).to_not include("Changed tags")
      end

      it "shows moderator actions when selected" do
        get "/moderations", params: {moderator: "alice"}

        expect(response).to be_successful
        expect(response.body).to include("Alice Moderation")
        expect(response.body).to_not include("Bob Moderation")
        expect(response.body).to_not include("Changed tags")
      end

      it "shows user actions when selected" do
        get "/moderations", params: {moderator: "(Users)"}

        expect(response).to be_successful
        expect(response.body).to_not include("Alice Moderation")
        expect(response.body).to_not include("Bob Moderation")
        expect(response.body).to include("Changed tags")
      end
    end

    context "when filtering entries by type" do
      let(:story) { create :story, title: "How to 10x your pipeline with this one weird trick" }

      it "shows entries matching the filters" do
        Moderation.create!(domain: domain, action: "Updated origin regex")
        Moderation.create!(story: story, action: "Edited title")

        get "/moderations", params: {what: {domains: "1"}}

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).not_to include(story.title)
      end
    end

    # https://github.com/lobsters/lobsters/issues/1425 - vulnerability scanner
    context "with extra params specified" do
      it "shows the page ignoring extra params", :aggregate_failures do
        # Ensure we end up with two pages of results
        (ModerationsController::ENTRIES_PER_PAGE * 2).times do
          Moderation.create!(domain: domain, action: "Did something useful, hopefully")
        end

        get "/moderations", params: {action: "u99p5"}

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).to include("Page 2")
      end
    end

    context "when filtering with no matching results" do
      it "shows an empty page without error", :aggregate_failures do
        # Create some domain moderations but no user moderations
        Moderation.create!(domain: domain, action: "Updated domain")

        # Filter for user moderations which don't exist
        get "/moderations", params: {what: {users: "users"}}

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).not_to include(domain.domain)
      end
    end
  end
end
