require 'rails_helper'

describe CommentsController do
  subject { response }
  let(:member) { FactoryBot.create(:member) }

  before(:each) do
    sign_in member
    controller.stub(:current_member) { member }
  end

  def valid_attributes
    @post = FactoryBot.create(:post)
    { post_id: @post.id, body: "some text" }
  end

  describe "GET RSS feed" do
    let!(:first_comment) { FactoryBot.create :comment, created_at: 10.days.ago }
    let!(:last_comment) { FactoryBot.create :comment, created_at: 4.minutes.ago }

    describe "returns an RSS feed" do
      before { get :index, format: "rss" }
      it { is_expected.to be_success }
      it { is_expected.to render_template("comments/index") }
      it { expect(response.content_type).to eq("application/rss+xml") }
      it { expect(assigns(:comments)).to eq([last_comment, first_comment]) }
    end
  end

  describe "GET new" do
    let(:post) { FactoryBot.create(:post) }

    describe "with valid params" do
      before { get :new, post_id: post.id }

      it "picks up post from params" do
        assigns(:post).should eq(post)
      end

      let(:old_comment) { FactoryBot.create(:comment, post: post) }

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
    let(:post) { FactoryBot.create(:post) }

    before { get :edit, id: comment.to_param }

    describe "my comment" do
      let!(:comment) { FactoryBot.create :comment, author: member, post: post }
      let!(:old_comment) { FactoryBot.create(:comment, post: post, created_at: Time.zone.yesterday) }

      it "assigns previous comments as @comments" do
        expect(assigns(:comments)).to eq([comment, old_comment])
      end
    end

    describe "not my comment" do
      let(:comment) { FactoryBot.create :comment, post: post }

      it { expect(response).not_to be_success }
    end
  end

  describe "PUT update" do
    before { put :update, id: comment.to_param, comment: valid_attributes }

    describe "my comment" do
      let(:comment) { FactoryBot.create :comment, author: member }

      it "redirects to the comment's post" do
        expect(response).to redirect_to(comment.post)
      end
    end
    describe "not my comment" do
      let(:comment) { FactoryBot.create :comment }

      it { expect(response).not_to be_success }
    end
    describe "attempting to change post_id" do
      let(:post) { FactoryBot.create :post, subject: 'our post' }
      let(:other_post) { FactoryBot.create :post, subject: 'the other post' }
      let(:valid_attributes) { { post_id: other_post.id, body: "kōrero" } }
      let(:comment) { FactoryBot.create :comment, author: member, post: post }

      it "does not change post_id" do
        comment.reload
        expect(comment.post_id).to eq(post.id)
      end
    end
  end

  describe "DELETE destroy" do
    before { delete :destroy, id: comment.to_param }

    describe "my comment" do
      let(:comment) { FactoryBot.create :comment, author: member }

      it "redirects to the post the comment was on" do
        expect(response).to redirect_to(comment.post)
      end
    end

    describe "not my comment" do
      let(:comment) { FactoryBot.create :comment }

      it { expect(response).not_to be_success }
    end
  end
end
