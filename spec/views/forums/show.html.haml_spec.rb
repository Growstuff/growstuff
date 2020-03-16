# frozen_string_literal: true

require 'rails_helper'

describe "forums/show" do
  before do
    controller.stub(:current_user) { nil }
    @forum = assign(:forum, FactoryBot.create(:forum))
  end

  it "renders attributes" do
    render
    expect(rendered).to have_content "Everything about permaculture"
    expect(rendered).to have_content @forum.owner.to_s
  end

  it "parses markdown description into html" do
    render
    assert_select "em", "Everything"
  end

  it 'links to new post with the forum id' do
    render
    assert_select "a[href='#{new_post_path(forum_id: @forum.id)}']"
  end

  it 'has no posts' do
    render
    expect(rendered).to have_content "No posts yet."
  end

  it 'shows posts' do
    @post = FactoryBot.create(:post, forum: @forum)
    render
    assert_select "table"
    expect(rendered).to have_content @post.subject
    expect(rendered).to have_content @post.author.to_s
  end
end
