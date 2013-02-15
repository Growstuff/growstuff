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

end
