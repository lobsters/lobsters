require 'rails_helper'

describe SearchController do
  describe '#index' do
    context 'when requesting html view' do
      it 'responses with oki' do
        get :index

        expect(response).to have_http_status(:ok)
      end
    end

    context 'when requested with another format' do
      it 'responses with a 404' do
        get :index, format: :rss

        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
