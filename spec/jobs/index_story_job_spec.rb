require 'rails_helper'

RSpec.describe IndexStoryJob, type: :job do
  let(:story) { create(:story) }

  it 'indexes a story' do
    client = double('Client')
    expect(ElasticSearch).to receive(:client).and_return(client).at_least(:once)
    expect(client).to receive(:index)

    subject.perform(story)
  end
end
