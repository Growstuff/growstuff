require 'rails_helper'

describe 'home/_open.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'has an open source section' do
    assert_select 'h2', 'Open Source'
  end

  it 'links to github' do
    assert_select 'a', :href => 'http://github.com/Growstuff/growstuff'
  end

  it 'has an open data section' do
    assert_select 'h2', 'Open Data and APIs'
  end

  it 'links to API docs' do
    assert_select 'a', :href => 'http://wiki.growstuff.org/index.php/API'
  end

  it 'has a get involved section' do
    assert_select 'h2', 'Get Involved'
  end

  it 'links to the mailing list' do
    assert_select 'a', :href => 'http://lists.growstuff.org/mailman/listinfo/discuss'
  end
end
