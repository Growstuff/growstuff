require 'spec_helper'

describe Forum do
  before(:each) do
    @forum = FactoryGirl.create(:forum)
  end

  it "belongs to an owner" do
    @forum.owner.should be_an_instance_of Member
  end

  it "has many posts" do
    @post1 = FactoryGirl.create(:forum_post, :forum => @forum)
    @post2 = FactoryGirl.create(:forum_post, :forum => @forum)
    @forum.posts.length.should == 2
  end

  it "orders posts in reverse chron order" do
    @post1 = FactoryGirl.create(:forum_post, :forum => @forum)
    @post2 = FactoryGirl.create(:forum_post, :forum => @forum)
    @forum.posts.first.should eq @post2
  end

end
