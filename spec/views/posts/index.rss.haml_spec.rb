require 'spec_helper'

describe 'posts/index.rss.haml', :type => "view" do
  before(:each) do
    controller.stub(:current_user) { nil }
    author = FactoryGirl.create(:member)
    @post1 = FactoryGirl.create(:post, :id => 1, :author => author)
    @post2 = FactoryGirl.create(:post, :id => 2, :author => author)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent posts from all members"
  end

  it 'shows content of posts' do
    rendered.should contain "This is some text."
  end

  it 'gives the author in the item title' do
    rendered.should contain "#{@post1.subject} by #{@post1.author}"
  end

end
