# frozen_string_literal: true

require 'rails_helper'

describe "posts/index" do
  before do
    controller.stub(:current_user) { nil }
    @author = FactoryBot.create(:member)
    page = 1
    per_page = 2
    total_entries = 2
    posts = WillPaginate::Collection.create(page, per_page, total_entries) do |pager|
      pager.replace([
                      FactoryBot.create(:post, author: @author,
                                               subject: 'A Post', body: 'This is some text.'),
                      FactoryBot.create(:post, author: @author,
                                               subject: 'A Post', body: 'This is some text.')
                    ])
    end
    assign(:posts, posts)
    render
  end

  it "renders a list of posts" do
    assert_select "div.post", count: 2
    assert_select "h4", text: "A Post", count: 2
    assert_select "p.post-body", text: "This is some text.", count: 2
  end

  it "contains two gravatar icons" do
    within '.posts' do
      assert_select "img", src: %r{gravatar\.com/avatar}, count: 2
    end
  end

  it "contains RSS feed links for posts and comments" do
    assert_select "a", href: posts_path(format: 'rss')
    assert_select "a", href: comments_path(format: 'rss')
  end
end
