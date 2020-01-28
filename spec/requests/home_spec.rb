require 'rails_helper'

describe 'home', type: :request do
  let(:user) { create(:user) }
  let(:story) { create(:story, user: user) }

  describe "#for_domain" do
    it 'returns 404 for non-existence domain' do
      expect { get '/domain/404.example.com' }.to raise_error(ActiveRecord::RecordNotFound)
    end

    it 'returns 200 for exsisting domains' do
      get "/domain/#{story.domain.domain}"

      expect(response).to be_successful
    end
  end
end
