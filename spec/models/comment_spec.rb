# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  context "basic" do
    let(:comment) { create(:comment) }

    it "belongs to a post" do
      comment.commentable.should be_an_instance_of Post
    end

    it "belongs to an author" do
      comment.author.should be_an_instance_of Member
    end
  end

  context "notifications" do
    it "sends a notification when a comment is posted" do
      expect do
        create(:comment)
      end.to change(Notification, :count).by(1)
    end

    it "sets the notification fields" do
      @c = create(:comment)
      @n = Notification.first
      @n.sender.should eq @c.author
      @n.recipient.should eq @c.commentable.author
      @n.subject.should include 'commented on'
      @n.body.should eq @c.body
      @n.notifiable.should eq @c.commentable # polymorphic association, this is a Post.
    end

    it "doesn't send notifications to yourself" do
      @m = create(:member)
      @p = create(:post, author: @m)
      expect do
        create(:comment, commentable: @p, author: @m)
      end.not_to change(Notification, :count)
    end
  end

  context "when the post author has blocked the comment author" do
    let(:post_author) { create(:member) }
    let(:comment_author) { create(:member) }
    let(:post) { create(:post, author: post_author) }

    before do
      post_author.blocks.create(blocked: comment_author)
    end

    it "is not valid" do
      comment = build(:comment, commentable: post, author: comment_author)
      expect(comment).not_to be_valid
    end
  end

  context "ordering" do
    before do
      @m = create(:member)
      @p = create(:post, author: @m)
      @c1 = create(:comment, commentable: @p, author: @m)
      @c2 = create(:comment, commentable: @p, author: @m)
    end

    it 'has a scope for ASC order for displaying on post page' do
      described_class.post_order.should eq [@c1, @c2]
    end
  end
end
