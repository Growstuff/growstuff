# frozen_string_literal: true

require 'rails_helper'

describe 'posts/index.rss.haml', type: "view" do
  before do
    controller.stub(:current_user) { nil }
    author = FactoryBot.create(:member)
    @post1 = FactoryBot.create(:post, id: 1, author: author, body: 'This is some text.')
    @post2 = FactoryBot.create(:post, id: 2, author: author)
    assign(:posts, [@post1, @post2])
    render
  end

  it 'shows RSS feed title' do
    expect(rendered).to have_content "Recent posts from all members"
  end

  it 'shows content of posts' do
    expect(rendered).to have_content "This is some text."
  end

  it 'gives the author in the item title' do
    expect(rendered).to have_content "#{@post1.subject} by #{@post1.author}"
  end
end
