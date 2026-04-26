# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  context "basic" do
    let(:comment) { create(:comment) }

    it "belongs to a post" do
      expect(comment.commentable).to be_an_instance_of Post
    end

    it "belongs to an author" do
      expect(comment.author).to be_an_instance_of Member
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
      expect(@n.sender).to eq @c.author
      expect(@n.recipient).to eq @c.commentable.author
      expect(@n.subject).to include 'commented on'
      expect(@n.body).to eq @c.body
      expect(@n.notifiable).to eq @c.commentable # polymorphic association, this is a Post.
    end

    it "doesn't send notifications to yourself" do
      @m = create(:member)
      @p = create(:post, author: @m)
      expect do
        create(:comment, commentable: @p, author: @m)
      end.not_to change(Notification, :count)
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
      expect(described_class.post_order).to eq [@c1, @c2]
    end
  end
end
