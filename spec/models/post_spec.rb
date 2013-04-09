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

  it "destroys comments when deleted" do
    @post = FactoryGirl.create(:post, :author => @member)
    @comment1 = FactoryGirl.create(:comment, :post => @post)
    @comment2 = FactoryGirl.create(:comment, :post => @post)
    @post.comments.length.should == 2
    all = Comment.count
    @post.destroy
    Comment.count.should == all - 2
  end

  it "belongs to a forum" do
    @post = FactoryGirl.create(:forum_post)
    @post.forum.should be_an_instance_of Forum
  end

  it "doesn't allow a blank subject" do
    @post = FactoryGirl.build(:post, :subject => nil)
    expect { @post.save }.to raise_error ActiveRecord::StatementInvalid
  end

  context "recent activity" do
    before(:each) do
      Time.stub(:now => Time.now)
      @post = FactoryGirl.create(:post)
    end

    it "sets recent activity to post time" do
      @post.recent_activity.to_i.should eq @post.created_at.to_i
    end

    it "sets recent activity to comment time" do
      @comment = FactoryGirl.create(:comment, :post => @post)
      @post.recent_activity.to_i.should eq @comment.created_at.to_i
    end

    it "sorts recently active" do
      # create a shiny new post
      @post2 = FactoryGirl.create(:post)
      Post.recently_active.first.should eq @post2
      # now comment on an older post
      @comment = FactoryGirl.create(:comment, :post => @post)
      Post.recently_active.first.should eq @post
    end
  end

end
