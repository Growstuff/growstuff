require 'rails_helper'

describe "comments/new" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @post = FactoryBot.create(:post)
    @comment = FactoryBot.create(:comment, post: @post)
    assign(:comment, @comment)
    assign(:comments, [@comment])
    render
  end

  it "shows the text of the post under discussion" do
    rendered.should have_content @post.body
  end

  it "shows previous comments" do
    rendered.should have_content @comment.body
  end

  it "shows the correct comment count" do
    rendered.should have_content "1 comment"
  end

  it "renders new comment form" do
    assert_select "form", action: comments_path, method: "post" do
      assert_select "textarea#comment_body", name: "comment[body]"
    end
  end

  it 'shows markdown help' do
    rendered.should have_content 'Markdown'
  end
end
