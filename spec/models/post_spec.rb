require 'spec_helper'

describe Post do
  before(:each) do
    @member = FactoryGirl.create(:member)
  end

  it "should be sorted in reverse order" do
    FactoryGirl.create(:post, :subject => 'first entry', :author => @member)
    FactoryGirl.create(:post, :subject => 'second entry', :author => @member)
    Post.first.subject.should == "second entry"
  end

  it "should have a slug" do
    @post = FactoryGirl.create(:post, :author => @member)
    @time = @post.created_at
    @datestr = @time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    @datestr.length.should == 4 + @time.year.to_s.size
    @post.slug.should == "#{@member.login_name}-#{@datestr}-a-post"
  end

  it "has many comments" do
    @post = FactoryGirl.create(:post, :author => @member)
    @comment1 = FactoryGirl.create(:comment, :post => @post)
    @comment2 = FactoryGirl.create(:comment, :post => @post)
    @post.comments.length.should == 2
  end
end
