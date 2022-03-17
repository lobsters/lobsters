require 'rails_helper'

describe 'tag routing' do
  it 'routes a single tag' do
    assert_recognizes({ controller: 'home', action: 'single_tag', tag: 'foo' }, '/t/foo')
  end

  it 'routes multiple tags' do
    assert_recognizes({ controller: 'home', action: 'multi_tag', tag: 'foo,bar' }, '/t/foo,bar')
  end

  # ONE tag has gotta be clever
  it 'routes the c++ tag' do
    assert_recognizes({ controller: 'home', action: 'single_tag', tag: 'c++' }, '/t/c++')
  end
end
