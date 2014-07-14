describe StoriesController do
  describe 'GET by_url' do
    let(:url) { 'http://example.com/cool-post' }

    subject(:parsed_response) { JSON.parse(response.body) }

    context 'story exists' do
      let!(:story) { Story.make! url: url }

      before { get :by_url, url: url, format: 'json' }

      it 'returns story' do
        expect(parsed_response['story']['is_recent?']).to eq true
      end
    end

    context 'story does not exists' do
      before { get :by_url, url: url, format: 'json' }

      it 'returns empty result' do
        expect(parsed_response['story']).to be_nil
      end
    end
  end
end
