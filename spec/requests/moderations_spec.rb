require "rails_helper"

RSpec.describe "moderations", type: :request do
  describe "#index" do
    let(:domain) { create :domain }

    context "with fewer entries than two pages" do
      it "shows the first page", :aggregate_failures do
        Moderation.create!(domain: domain)
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
          Moderation.create!(domain: domain)
        end

        get "/moderations"

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).to include("Page 2")
      end
    end

    context "when filtering entries by type" do
      let(:story) { create :story, title: "How to 10x your pipeline with this one weird trick" }

      it "shows entries matching the filters" do
        Moderation.create!(domain: domain)
        Moderation.create!(story: story)

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
          Moderation.create!(domain: domain)
        end

        get "/moderations", params: {action: "u99p5"}

        expect(response).to be_successful
        expect(response.body).to include("Moderation Log")
        expect(response.body).to include(domain.domain)
        expect(response.body).to include("Page 2")
      end
    end
  end
end
