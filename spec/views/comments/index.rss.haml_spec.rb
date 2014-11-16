require 'rails_helper'

describe 'comments/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryGirl.create(:member)
    @post = FactoryGirl.create(:post)
    assign(:comments, [
      FactoryGirl.create(:comment, :author => @author, :post => @post),
      FactoryGirl.create(:comment, :author => @author, :post => @post)
    ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should contain "Recent comments on all posts"
  end

  it 'shows item title' do
    rendered.should contain "Comment by #{@author.login_name}"
  end

  it 'escapes html for link to post' do
    # it's then unescaped by 'render' so we don't actually look for &lt;
    rendered.should contain '<a href='
  end

  it 'shows content of comments' do
    rendered.should contain "OMG LOL"
  end

end
