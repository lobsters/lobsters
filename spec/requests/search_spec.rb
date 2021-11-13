require "rails_helper"

RSpec.describe "Search Controller", :type => :request do

  describe 'Request' do
    context 'check view index' do
      it 'Status Okay' do
        get "/search"
        expect(response).to have_http_status(:ok)
      end

      it 'get data search' do
        get "/search", :params => {:q=>'aaa'}

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('0 results for "aaa"')
        expect(response.content_type).to eq('text/html; charset=utf-8')
      end

      it 'check other params' do
        get "/search", :params => {:q=>'a%aa%', :what =>'stories', :order => 'relevance'}
        expect(response).to have_http_status(:ok)
      end
    end

    context 'Bad request via POST' do
      it 'routing error' do
        expect{ post "/search", :params => {:q => 'asdasd'} }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'sanitize' do

      it 'add another params url' do
        get '/search', :params => {:q => 'alcohol%2070%'}
        expect(response).to have_http_status(:ok)
      end

    end
  end

end
