# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  describe "basic" do
    let(:comment) { create(:comment) }

    it "belongs to a post" do
      expect(comment.commentable).to be_an_instance_of Post
    end

    it "belongs to an author" do
      expect(comment.author).to be_an_instance_of Member
    end
  end

  describe "notifications" do
    it "sends a notification when a comment is posted on a post" do
      expect do
        create(:comment)
      end.to change(Notification, :count).by(1)
    end

    it "sends a notification when a comment is posted on a planting" do
      planting = create(:planting)
      expect do
        create(:comment, commentable: planting)
      end.to change(Notification, :count).by(1)
    end

    describe "the notification" do
      let!(:comment) { create(:comment) }
      let(:notification) { Notification.first }

      it { expect(notification.sender).to eq comment.author }
      it { expect(notification.recipient).to eq comment.commentable.author }
      it { expect(notification.subject).to include 'commented on' }
      it { expect(notification.body).to eq comment.body }
      # A polymorphic association, this is a Post.
      it { expect(notification.notifiable).to eq comment.commentable }
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

  describe "ordering" do
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

  describe 'updating author spam score' do
    let(:member) { create(:member) }
    let(:post) { create(:post) }

    it 'triggers update_spam_score! on author after save' do
      expect(member).to receive(:update_spam_score!)
      create(:comment, author: member, commentable: post)
    end
  end
end
