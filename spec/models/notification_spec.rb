require 'spec_helper'

describe Notification do
  before(:each) do
    @notification = FactoryGirl.create(:notification)
  end

  it "belongs to a post" do
    @notification.post.should be_an_instance_of Post
  end

  it "belongs to a recipient" do
    @notification.recipient.should be_an_instance_of Member
  end

  it "belongs to a sender" do
    @notification.sender.should be_an_instance_of Member
  end

  it "has a scope for unread" do
    Notification.unread.should eq [@notification]
    @n2 = FactoryGirl.create(:notification, :read => true)
    Notification.unread.should eq [@notification]
    @n3 = FactoryGirl.create(:notification, :read => false)
    Notification.unread.should eq [@n3, @notification]
  end

  it "counts unread" do
    @who = @notification.recipient
    @n2 = FactoryGirl.create(:notification, :recipient => @who, :read => false)
    @who.notifications.unread_count.should eq 2
  end

end
