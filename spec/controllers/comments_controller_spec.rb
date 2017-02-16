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
    { post_id: @post.id, body: "some text" }
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
    let(:post) { FactoryGirl.create(:post) }

    describe "with valid params" do
      before { get :new, post_id: post.id }

      it "picks up post from params" do
        assigns(:post).should eq(post)
      end

      let(:old_comment) { FactoryGirl.create(:comment, post: post) }
      it "assigns the old comments as @comments" do
        assigns(:comments).should eq [old_comment]
      end
    end

    it "dies if no post specified" do
      get :new
      expect(response).not_to be_success
    end
  end

  describe "GET edit" do
    let(:post) { FactoryGirl.create(:post) }
    before { get :edit, id: comment.to_param }

    describe "my comment" do
      let!(:comment) { FactoryGirl.create :comment, author: @member, post: post }
      let!(:old_comment) { FactoryGirl.create(:comment, post: post, created_at: Time.zone.yesterday) }
      it "assigns previous comments as @comments" do
        assigns(:comments).should eq([comment, old_comment])
      end
    end

    describe "not my comment" do
      let(:comment) { FactoryGirl.create :comment, post: post }
      it { expect(response).not_to be_success }
    end
  end

  describe "PUT update" do
    before { put :update, id: comment.to_param, comment: valid_attributes }

    describe "my comment" do
      let(:comment) { FactoryGirl.create :comment, author: @member }
      it "redirects to the comment's post" do
        expect(response).to redirect_to(comment.post)
      end
    end
    describe "not my comment" do
      let(:comment) { FactoryGirl.create :comment }
      it { expect(response).not_to be_success }
    end
  end

  describe "DELETE destroy" do
    before { delete :destroy, id: comment.to_param }

    describe "my comment" do
      let(:comment) { FactoryGirl.create :comment, author: @member }
      it "redirects to the post the comment was on" do
        expect(response).to redirect_to(comment.post)
      end
    end

    describe "not my comment" do
      let(:comment) { FactoryGirl.create :comment }
      it { expect(response).not_to be_success }
    end
  end
end
