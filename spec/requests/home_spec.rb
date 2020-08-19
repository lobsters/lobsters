require 'rails_helper'

describe 'home', type: :request do
  describe "#category" do
    it 'lists stories in the category' do
      story = create(:story)
      get "/categories/#{story.tags.first.category.category}"

      expect(response).to be_successful
      expect(response.body).to include(story.title)
    end
  end

  describe "#for_domain" do
    it 'returns 404 for non-existent domain' do
      expect { get '/domain/unseen.domain' }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 200 for existing domains' do
      story = create(:story)
      get "/domain/#{story.domain.domain}"

      expect(response).to be_successful
      expect(response.body).to include(story.title)
    end
  end
end
