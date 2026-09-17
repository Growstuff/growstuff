# frozen_string_literal: true

require 'rails_helper'

describe CommentsController do
  subject { response }

  let(:member) { create(:member) }

  before do
    sign_in member
    controller.stub(:current_member) { member }
  end

  def valid_attributes
    @post = create(:post)
    { post_id: @post.id, body: "some text" }
  end

  describe "GET RSS feed" do
    let!(:first_comment) { create(:comment, created_at: 10.days.ago) }
    let!(:last_comment) { create(:comment, created_at: 4.minutes.ago) }

    describe "returns an RSS feed" do
      before { get :index, format: "rss" }

      it { is_expected.to be_successful }
      it { is_expected.to render_template("comments/index") }
      it { expect(response.content_type).to eq("application/rss+xml; charset=utf-8") }
      it { expect(assigns(:comments)).to eq([last_comment, first_comment]) }
    end
  end

  describe "GET new" do
    let(:post) { create(:post) }

    describe "with valid params" do
      before do
        get :new, params: {
          comment: { commentable_id: post.id, commentable_type: "Post" }
        }
      end

      let(:old_comment) { create(:comment, commentable: post) }

      it "picks up post from params" do
        expect(assigns(:commentable)).to eq(post)
      end

      it "assigns the old comments as @comments" do
        expect(assigns(:comments)).to eq [old_comment]
      end
    end

    it "dies if no post specified" do
      get :new
      expect(response).not_to be_successful
    end
  end

  describe "GET edit" do
    let(:post) { create(:post) }

    before { get :edit, params: { id: comment.to_param } }

    describe "my comment" do
      let!(:comment)     { create(:comment, author: member, commentable: post) }
      let!(:old_comment) { create(:comment, commentable: post, created_at: Time.zone.yesterday) }

      it "assigns previous comments as @comments" do
        expect(assigns(:comments)).to eq([comment, old_comment])
      end
    end

    describe "not my comment" do
      let(:comment) { create(:comment, commentable: post) }

      it { expect(response).not_to be_successful }
    end
  end

  describe "PUT update" do
    before { put :update, params: { id: comment.to_param, comment: valid_attributes } }

    describe "my comment" do
      let(:comment) { create(:comment, author: member) }

      it "redirects to the comment's post" do
        expect(response).to redirect_to(comment.commentable)
      end
    end

    describe "not my comment" do
      let(:comment) { create(:comment) }

      it { expect(response).not_to be_successful }
    end

    describe "attempting to change post_id" do
      let(:post)             { create(:post, subject: 'our post')           }
      let(:other_post)       { create(:post, subject: 'the other post')     }
      let(:valid_attributes) { { commentable_type: "Post", commentable_id: other_post.id, body: "kōrero" } }
      let(:comment)          { create(:comment, author: member, commentable: post) }

      it "does not change post_id" do
        comment.reload
        expect(comment.commentable_id).to eq(post.id)
      end
    end
  end

  describe "DELETE destroy" do
    before { delete :destroy, params: { id: comment.to_param } }

    describe "my comment" do
      let(:comment) { create(:comment, author: member) }

      it "redirects to the post the comment was on" do
        expect(response).to redirect_to(comment.commentable)
      end
    end

    describe "not my comment" do
      let(:comment) { create(:comment) }

      it { expect(response).not_to be_successful }
    end
  end
end
