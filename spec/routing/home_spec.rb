require 'rails_helper'

describe 'home routing' do
  it 'routes a domain' do
    assert_recognizes(
      { controller: 'home', action: 'for_domain', name: 'example.com' },
      '/domain/example.com'
    )
  end

  it 'routes a domain rss feed' do
    assert_recognizes(
      { controller: 'home', action: 'for_domain', name: 'example.com', format: 'rss' },
      '/domain/example.com.rss'
    )
  end
end
