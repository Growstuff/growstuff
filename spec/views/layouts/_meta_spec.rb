require 'spec_helper'

describe 'layouts/_meta.html.haml', :type => "view" do
  before(:each) do
    render
  end

  it 'should have RSS links in the head' do
    assert_select "head>link", :href => url_for(:controller => 'posts', :format => 'rss')
    assert_select "head>link", :href => url_for(:controller => 'crops', :format => 'rss')
  end

end
