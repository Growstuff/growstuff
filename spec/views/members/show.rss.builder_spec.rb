require 'spec_helper'

describe 'members/show.rss.builder', :type => "view" do
  before(:each) do
    @member = assign(:member, FactoryGirl.create(:user))
    assign(:posts, [
      FactoryGirl.build(:post, :id => 1, :user => @member),
      FactoryGirl.build(:post, :id => 2, :user => @member)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "user1's recent posts"
  end

  it 'shows content of posts' do
    rendered.should contain "This is some text."
  end

end
