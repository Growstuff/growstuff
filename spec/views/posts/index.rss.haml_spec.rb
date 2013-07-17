require 'spec_helper'

describe 'posts/index.rss.haml', :type => "view" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    assign(:posts, [
      FactoryGirl.build(:post, :id => 1, :author => @author),
      FactoryGirl.build(:post, :id => 2, :author => @author)
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
