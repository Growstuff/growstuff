require 'spec_helper'

describe Comment do

  before(:each) do
    @comment = FactoryGirl.create(:comment)
  end

  it "belongs to a post" do
    @comment.post.should be_an_instance_of Post
  end

  it "belongs to an author" do
    @comment.author.should be_an_instance_of Member
  end

  it "sends a notification when a comment is posted" do
    expect {
      FactoryGirl.create(:comment)
    }.to change(Notification, :count).by(1)
  end

  it "sets the notification fields" do
    @c = FactoryGirl.create(:comment)
    @n = Notification.first
    @n.sender.should eq @c.author
    @n.recipient.should eq @c.post.author
    @n.subject.should match /commented on/
    @n.body.should eq @c.body
    @n.post.should eq @c.post
  end

  it "doesn't send notifications to yourself" do
    @m = FactoryGirl.create(:member)
    @p = FactoryGirl.create(:post, :author => @m)
    expect {
      FactoryGirl.create(:comment, :post => @p, :author => @m)
    }.to change(Notification, :count).by(0)
  end

end
