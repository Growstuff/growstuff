require 'spec_helper'

describe 'posts/index.rss.builder', :type => "view" do
  before(:each) do
    @member = FactoryGirl.create(:member)
    assign(:recent_posts, [
      FactoryGirl.build(:post, :id => 1, :member => @member),
      FactoryGirl.build(:post, :id => 2, :member => @member)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent posts from all members"
  end

  it 'shows content of posts' do
    rendered.should contain "This is some text."
  end

end
