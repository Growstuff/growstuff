require 'spec_helper'

describe 'posts/show.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    @post = FactoryGirl.create(:post)
    FactoryGirl.create(:comment, :author => @author, :post => @post)
    FactoryGirl.create(:comment, :author => @author, :post => @post)
    assign(:post, @post)
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent comments on #{@post.subject}"
  end

  it 'escapes html for link to post' do
    # it's then unescaped by 'render' so we don't actually look for &lt;
    rendered.should contain '<a href='
  end

  it 'shows content of comments' do
    rendered.should contain "OMG LOL"
  end

end
