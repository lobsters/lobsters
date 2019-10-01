require 'rails_helper'

describe SearchController do
  describe '#index' do
    it 'response okish for html requests' do
      get :index

      expect(response).to have_http_status(:ok)
    end

    it 'responses with a 404 for rss requests' do
      get :index, format: :rss

      expect(response).to have_http_status(:not_found)
    end
  end
end
