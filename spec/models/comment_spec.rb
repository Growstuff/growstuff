# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  context "basic" do
    let(:comment) { FactoryBot.create(:comment) }

    it "belongs to a post" do
      comment.post.should be_an_instance_of Post
    end

    it "belongs to an author" do
      comment.author.should be_an_instance_of Member
    end
  end

  context "notifications" do
    it "sends a notification when a comment is posted" do
      expect do
        FactoryBot.create(:comment)
      end.to change(Notification, :count).by(1)
    end

    it "sets the notification fields" do
      @c = FactoryBot.create(:comment)
      @n = Notification.first
      @n.sender.should eq @c.author
      @n.recipient.should eq @c.post.author
      @n.subject.should include 'commented on'
      @n.body.should eq @c.body
      @n.post.should eq @c.post
    end

    it "doesn't send notifications to yourself" do
      @m = FactoryBot.create(:member)
      @p = FactoryBot.create(:post, author: @m)
      expect do
        FactoryBot.create(:comment, post: @p, author: @m)
      end.to change(Notification, :count).by(0)
    end
  end

  context "ordering" do
    before do
      @m = FactoryBot.create(:member)
      @p = FactoryBot.create(:post, author: @m)
      @c1 = FactoryBot.create(:comment, post: @p, author: @m)
      @c2 = FactoryBot.create(:comment, post: @p, author: @m)
    end

    it 'has a scope for ASC order for displaying on post page' do
      described_class.post_order.should eq [@c1, @c2]
    end
  end
end
