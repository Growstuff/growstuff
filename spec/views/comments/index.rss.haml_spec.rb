require 'rails_helper'

describe 'comments/index.rss.haml' do
  before(:each) do
    controller.stub(:current_user) { nil }
    @author = FactoryBot.create(:member)
    @post = FactoryBot.create(:post)
    assign(:comments, [
             FactoryBot.create(:comment, author: @author, post: @post),
             FactoryBot.create(:comment, author: @author, post: @post)
           ])
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recent comments on all posts"
  end

  it 'shows item title' do
    rendered.should have_content "Comment by #{@author.login_name}"
  end

  it 'escapes html for link to post' do
    # it's then unescaped by 'render' so we don't actually look for &lt;
    rendered.should have_content '<a href='
  end

  it 'shows content of comments' do
    rendered.should have_content "OMG LOL"
  end
end
