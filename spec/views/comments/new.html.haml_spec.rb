## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe "comments/new" do
  before(:each) do
    controller.stub(:current_user) { nil }
    @post = FactoryGirl.create(:post)
    @comment = FactoryGirl.create(:comment, post: @post)
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
