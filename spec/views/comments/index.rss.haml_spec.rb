# frozen_string_literal: true

require 'rails_helper'

describe 'comments/index.rss.haml' do
  before do
    allow(controller).to receive(:current_user).and_return(nil)
    @author = create(:member)
    @post = create(:post)
    assign(:comments, [
             create(:comment, author: @author, commentable: @post),
             create(:comment, author: @author, commentable: @post)
           ])
    render
  end

  it 'shows RSS feed title' do
    expect(rendered).to have_content "Recent comments on all posts"
  end

  it 'shows item title' do
    expect(rendered).to have_content "Comment by #{@author.login_name}"
  end

  it 'escapes html for link to post' do
    # it's then unescaped by 'render' so we don't actually look for &lt;
    expect(rendered.to_s).to have_content '<a href='
  end

  it 'shows content of comments' do
    expect(rendered).to have_content "OMG LOL"
  end
end
