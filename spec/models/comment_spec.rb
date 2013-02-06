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
end
