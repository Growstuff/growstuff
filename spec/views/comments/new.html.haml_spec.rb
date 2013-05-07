require 'spec_helper'

describe "comments/new" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @post = FactoryGirl.create(:post)
    @previous_comment = FactoryGirl.create(:comment, :post => @post)
    assign(:comment, FactoryGirl.create(:comment, :post => @post))
    assign(:comments, [@previous_comment])
    render
  end

  it "shows the text of the post under discussion" do
    rendered.should contain @post.body
  end

  it "shows previous comments" do
    rendered.should contain @previous_comment.body
  end

  it "shows the correct comment count" do
    rendered.should contain "1 comment"
  end

  it "renders new comment form" do
    assert_select "form", :action => comments_path, :method => "post" do
      assert_select "textarea#comment_body", :name => "comment[body]"
    end
  end

  it 'shows markdown help' do
    rendered.should contain 'Markdown'
  end

end
