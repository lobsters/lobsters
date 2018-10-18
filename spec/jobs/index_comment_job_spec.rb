require 'rails_helper'

RSpec.describe IndexCommentJob, type: :job do
  let(:comment) { create(:comment) }

  it 'indexes a comment' do
    client = double('Client')
    expect(ElasticSearch).to receive(:client).and_return(client).at_least(:once)
    expect(client).to receive(:index)

    subject.perform(comment)
  end
end
