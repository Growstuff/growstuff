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

describe CommentsController do

  before(:each) do
    @member = FactoryGirl.create(:member)
    sign_in @member
    controller.stub(:current_member) { @member }
  end

  def valid_attributes
    @post = FactoryGirl.create(:post)
    { post_id: @post.id, author_id: @member.id, body: "some text" }
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, format: "rss"
      response.should be_success
      response.should render_template("comments/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

  describe "GET new" do
    it "picks up post from params" do
      post = FactoryGirl.create(:post)
      get :new, {post_id: post.id}
      assigns(:post).should eq(post)
    end

    it "assigns the old comments as @comments" do
      post = FactoryGirl.create(:post)
      old_comment = FactoryGirl.create(:comment, post: post)
      get :new, {post_id: post.id}
      assigns(:comments).should eq [old_comment]
    end

    it "dies if no post specified" do
      get :new
      response.should redirect_to(root_url)
    end
  end

  describe "GET edit" do
    it "assigns previous comments as @comments" do
      post = FactoryGirl.create(:post)
      old_comment = FactoryGirl.create(:comment, post: post)
      comment = FactoryGirl.create(:comment, post: post, author: @member)
      get :edit, {id: comment.to_param}
      assigns(:comments).should eq([comment, old_comment])
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "redirects to the comment's post" do
        comment = Comment.create! valid_attributes
        put :update, {id: comment.to_param, comment: valid_attributes}
        response.should redirect_to(comment.post)
      end
    end
  end

  describe "DELETE destroy" do
    it "redirects to the post the comment was on" do
      comment = Comment.create! valid_attributes
      post = comment.post
      delete :destroy, {id: comment.to_param}
      response.should redirect_to(post)
    end
  end

end
