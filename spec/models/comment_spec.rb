# frozen_string_literal: true

require 'rails_helper'

describe Comment do
  context "associations" do
    let(:member) { FactoryBot.create(:member) } # Common author

    it "belongs to a commentable (Post)" do
      post = FactoryBot.create(:post, author: member)
      comment = FactoryBot.create(:comment, commentable: post, author: member)
      comment.commentable.should be_an_instance_of Post
    end

    it "belongs to a commentable (Photo)" do
      photo = FactoryBot.create(:photo, owner: member)
      comment = FactoryBot.create(:comment, commentable: photo, author: member)
      comment.commentable.should be_an_instance_of Photo
    end

    it "belongs to a commentable (Planting)" do
      planting = FactoryBot.create(:planting, owner: member)
      comment = FactoryBot.create(:comment, commentable: planting, author: member)
      comment.commentable.should be_an_instance_of Planting
    end

    it "belongs to a commentable (Harvest)" do
      harvest = FactoryBot.create(:harvest, owner: member)
      comment = FactoryBot.create(:comment, commentable: harvest, author: member)
      comment.commentable.should be_an_instance_of Harvest
    end

    it "belongs to a commentable (Activity)" do
      activity = FactoryBot.create(:activity, owner: member)
      comment = FactoryBot.create(:comment, commentable: activity, author: member)
      comment.commentable.should be_an_instance_of Activity
    end

    it "belongs to an author" do
      comment = FactoryBot.create(:comment, author: member) # Default commentable is Post
      comment.author.should be_an_instance_of Member
    end
  end

  RSpec.shared_examples "comment notifications" do |commentable_type, commentable_factory_name|
    let(:commentable_owner) { FactoryBot.create(:member) }
    let(:comment_author) { FactoryBot.create(:member) }
    let!(:commentable) do
      # For :post, the owner is :author. For others, it's :owner.
      if commentable_factory_name == :post
        FactoryBot.create(commentable_factory_name, author: commentable_owner)
      else
        FactoryBot.create(commentable_factory_name, owner: commentable_owner)
      end
    end

    it "sends a notification when a comment is posted" do
      expect do
        FactoryBot.create(:comment, commentable: commentable, author: comment_author)
      end.to change(Notification, :count).by(1)
    end

    it "sets the notification fields correctly" do
      comment = FactoryBot.create(:comment, commentable: commentable, author: comment_author)
      notification = Notification.last # More robust than Notification.first
      notification.sender.should eq comment.author
      notification.recipient.should eq commentable_owner
      notification.subject.should include "commented on your #{commentable_type.downcase}"
      notification.body.should eq comment.body
      notification.commentable_id.should eq commentable.id
      notification.commentable_type.should eq commentable_type
    end

    it "doesn't send notifications to yourself (when comment author is commentable owner)" do
      expect do
        FactoryBot.create(:comment, commentable: commentable, author: commentable_owner)
      end.not_to change(Notification, :count)
    end
  end

  context "notifications for Post" do
    include_examples "comment notifications", "Post", :post
  end

  context "notifications for Photo" do
    include_examples "comment notifications", "Photo", :photo
  end

  context "notifications for Planting" do
    include_examples "comment notifications", "Planting", :planting
  end

  context "notifications for Harvest" do
    include_examples "comment notifications", "Harvest", :harvest
  end

  context "notifications for Activity" do
    include_examples "comment notifications", "Activity", :activity
  end

  RSpec.shared_examples "comment to_s method" do |commentable_type, commentable_factory_name|
    let(:commentable_owner) { FactoryBot.create(:member) }
    let(:comment_author) { FactoryBot.create(:member, login_name: "CommenterUser") }
    let!(:commentable) do
      # For :post, the owner is :author. For others, it's :owner.
      obj = if commentable_factory_name == :post
              FactoryBot.create(commentable_factory_name, author: commentable_owner)
            else
              FactoryBot.create(commentable_factory_name, owner: commentable_owner)
            end
      # Ensure commentable has a consistent ID for the test if possible, or just use its class name
      obj
    end
    let(:comment) { FactoryBot.create(:comment, commentable: commentable, author: comment_author) }

    it "returns a descriptive string" do
      expected_string = "#{comment_author.login_name} commented on #{commentable_type.downcase} ##{commentable.id}"
      comment.to_s.should eq expected_string
    end
  end

  context "to_s method for Post" do
    include_examples "comment to_s method", "Post", :post
  end

  context "to_s method for Photo" do
    include_examples "comment to_s method", "Photo", :photo
  end

  context "to_s method for Planting" do
    include_examples "comment to_s method", "Planting", :planting
  end

  context "to_s method for Harvest" do
    include_examples "comment to_s method", "Harvest", :harvest
  end

  context "to_s method for Activity" do
    include_examples "comment to_s method", "Activity", :activity
  end

  context "ordering" do
    before do
      @m = FactoryBot.create(:member)
      # Ensure the commentable for ordering test is a Post, as it was originally
      @p = FactoryBot.create(:post, author: @m)
      @c1 = FactoryBot.create(:comment, commentable: @p, author: @m)
      @c2 = FactoryBot.create(:comment, commentable: @p, author: @m)
    end

    it 'has a scope for ASC order for displaying on commentable page' do # Renamed for clarity
      described_class.post_order.should eq [@c1, @c2]
    end
  end
end
