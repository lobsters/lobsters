require 'spec_helper.rb'

describe StoriesController do
  describe '#ensure_preview' do
    subject { controller.send(:ensure_preview) }
    it 'stubs out a story object to display to user' do
      allow(controller).to receive(:params) { {} }
      is_expected.to eq(story: {
                                 title: '',
                                 description: '',
                                 tags_a: ['']
                               })
    end

    it 'stubs out a story object for missing data only' do
      allow(controller).to receive(:params) { {story: {title: 'something'} } }
      is_expected.to eq(story: {
                                 title: 'something',
                                 description: '',
                                 tags_a: ['']
                               })
    end
  end
end