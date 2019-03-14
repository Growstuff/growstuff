# frozen_string_literal: true

require 'rails_helper'

describe 'posts/show.rss.haml' do
  before do
    controller.stub(:current_user) { nil }
    @author = FactoryBot.create(:member)
    @post = FactoryBot.create(:post)
    FactoryBot.create(:comment, author: @author, post: @post)
    FactoryBot.create(:comment, author: @author, post: @post)
    assign(:post, @post)
    render
  end

  it 'shows RSS feed title' do
    rendered.should have_content "Recent comments on #{@post.subject}"
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
