# frozen_string_literal: true

require 'rails_helper'

describe "comments/new" do
  before do
    controller.stub(:current_user) { nil }
    @post = FactoryBot.create(:post, body: 'tena koutou ki te ao')
    @comment = FactoryBot.create(:comment, post: @post)
    assign(:comment, @comment)
    assign(:comments, [@comment])
    render
  end

  it "shows the text of the post under discussion" do
    expect(rendered).to have_content @post.body
  end

  it "shows previous comments" do
    expect(rendered).to have_content @comment.body
  end

  it "shows the correct comment count" do
    expect(rendered).to have_content "1 comment"
  end

  it "renders new comment form" do
    assert_select "form", action: comments_path, method: "post" do
      assert_select "textarea#comment_body", name: "comment[body]"
    end
  end

  it 'shows markdown help' do
    expect(rendered).to have_content 'Markdown'
  end
end
