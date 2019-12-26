# frozen_string_literal: true

require 'rails_helper'

describe "posts/_single" do
  def render_post
    render partial: "single", locals: { post: @post }
  end

  before do
    @post = FactoryBot.create(:post)
    controller.stub(:current_user) { nil }
  end

  context "when the number of comments doesn't matter" do
    before do
      render_post
    end

    it "contains a permanent link to post" do
      assert_select "a[href='#{post_path @post}']", "Permalink"
    end

    it "doesn't contain a link to new comment" do
      assert_select("a", { href: new_comment_path(post_id: @post.id) }, false)
    end
  end

  context "when logged in" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      render_post
    end

    it "contains link to new comment" do
      assert_select("a", { href: new_comment_path(post_id: @post.id) }, "Reply")
    end

    it "does not contain an edit link" do
      assert_select "a[href='#{edit_post_path(@post)}']", false
    end
  end

  context "when logged in as post author" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @post = FactoryBot.create(:post, author: @member)
      render_post
    end
  end

  context "when post has been edited" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @post = FactoryBot.create(:post, author: @member)
      @post.update(body: "I am updated")
      render_post
    end

    it "shows edited at" do
      rendered.should have_content "edited at"
    end

    it "shows the updated time" do
      rendered.should have_content @post.updated_at
    end
  end

  context "when comment has been edited" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @post = FactoryBot.create(:post, author: @member)
      @comment = FactoryBot.create(:comment, post: @post)
      @comment.update(body: "I've been updated")
      render partial: "comments/single", locals: { comment: @comment }
    end

    it "shows edited at time" do
      rendered.should have_content "edited at"
    end

    it "shows updated time" do
      rendered.should have_content @comment.updated_at
    end
  end

  context "when post has not been edited" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @post = FactoryBot.create(:post, author: @member)
      @post.update(updated_at: @post.created_at)
      render_post
    end

    it "does not show edited at" do
      rendered.should_not have_content "edited at #{@post.updated_at}"
    end
  end

  context "when comment has not been edited" do
    before do
      @member = FactoryBot.create(:member)
      sign_in @member
      controller.stub(:current_user) { @member }
      @post = FactoryBot.create(:post, author: @member)
      @comment = FactoryBot.create(:comment, post: @post)
      @comment.update(updated_at: @comment.created_at)
      render partial: "comments/single", locals: { comment: @comment }
    end

    it "does not show edited at" do
      rendered.should_not have_content "edited at #{@comment.updated_at}"
    end
  end
end
