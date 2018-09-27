require "rails_helper"

describe StoriesController do
  let(:story) { create(:story, title: "mytitle") }
  let(:other_story) { create(:story, title: "myothertitle") }

  let(:json_response) { JSON.parse(response.body) }

  context 'index' do
    context 'html' do
      it 'redirects to search when scoped' do
        get :index, params: { q: "myquery" }

        expect(response).to redirect_to search_path
      end

      it 'redirects to root when unscoped' do
        get :index

        expect(response).to redirect_to root_path
      end
    end

    context 'json' do
      it 'returns Search#results when scoped' do
        search = Search.new

        allow(search).to receive(:results) { Story.all }
        allow(Search).to receive(:new) { search }

        get :index, format: :json, params: { q: story.title }

        expect(response).to be_successful

        results = json_response.fetch("results")
        expect(results.count).to eq(1)
        expect(results.first["title"]).to eq(story.title)

        expect(json_response.fetch("meta")).to eq({
          "page" => 1,
          "page_count" => 1,
          "total_results" => 1
        })
      end

      it "accepts page param when scoped" do
        page = 2
        search = Search.new

        expect(search).to receive(:page=).with(page)
        allow(Search).to receive(:new) { search }

        get :index, format: :json, params: { q: story.title, page: page }

        expect(response).to be_successful
      end

      it "accepts order param when scoped" do
        order = "newest"
        search = Search.new

        expect(search).to receive(:order=).with(order)
        allow(Search).to receive(:new) { search }

        get :index, format: :json, params: { q: story.title, order: order }

        expect(response).to be_successful
      end

      it 'returns empty results when non-matching query' do
        get :index, format: :json, params: { q: "myquery" }

        expect(response).to be_successful
        expect(json_response.fetch("results")).to eq([])
        expect(json_response.fetch("meta")).to eq({
          "page" => 1,
          "page_count" => 1,
          "total_results" => 0
        })
      end

      it 'returns error when unscoped' do
        get :index, format: :json

        expect(response.status).to eq(422)
        expect(json_response).to eq({ "message" => "Missing parameter: q" })
      end
    end
  end
end
