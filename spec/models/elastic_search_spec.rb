require "rails_helper"

describe ElasticSearch do
  subject { described_class.new(q: 'Hello', what: 'comments', page: 20, per_page: 5) }

  it 'must be valid' do
    expect(subject.valid?).to be(true)
  end

  it 'builds an approprate query' do
    from = subject.page * subject.per_page

    searcher = double('Search Client')
    expect(Elasticsearch::Client).to receive(:new).and_return(searcher)
    expect(searcher).to receive(:search)
                          .with(from: from,
                                index: "lobsters-search",
                                q: subject.q + ' AND kind:comment NOT is_expired:true',
                                size: subject.per_page,
                                sort: subject.sort)
                          .and_return('hits' => { 'hits' => [], 'total' => 0 })

    subject.search_for_user!(nil)
  end

  it 'changes type based on what' do
    expect(described_class.new(what: 'comments').type).to eq('comment')
    expect(described_class.new(what: 'stories').type).to eq('story')
  end

  it 'changes sort based on order' do
    expect(described_class.new(order: 'relevance').sort).to eq('_score:asc')
    expect(described_class.new(order: 'newest').sort).to eq('created_at:asc')
    expect(described_class.new(order: 'points').sort).to eq('score:asc')
  end
end
