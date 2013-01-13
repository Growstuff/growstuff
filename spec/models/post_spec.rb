require 'spec_helper'

describe Post do
  before(:each) do
    @user = FactoryGirl.create(:user)
  end

  it "should be sorted in reverse order" do
    FactoryGirl.create(:post, :subject => 'first entry', :user => @user)
    FactoryGirl.create(:post, :subject => 'second entry', :user => @user)
    Post.first.subject.should == "second entry"
  end

  it "should have a slug" do
    @post = FactoryGirl.create(:post, :user => @user)
    @time = @post.created_at
    @datestr = @time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    @datestr.length.should == 4 + @time.year.to_s.size
    @post.slug.should == "#{@user.username}-#{@datestr}-a-post"
  end
end
