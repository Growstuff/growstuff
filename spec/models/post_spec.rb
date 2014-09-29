require 'spec_helper'

describe Post do
  before(:each) do
    @member = FactoryGirl.create(:member)
  end

  it "should be sorted in reverse order" do
    FactoryGirl.create(:post,
      :subject => 'first entry',
      :author => @member,
      :created_at => 2.days.ago
    )
    FactoryGirl.create(:post,
      :subject => 'second entry',
      :author => @member,
      :created_at => 1.day.ago
    )
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

  it "doesn't allow a nil subject" do
    @post = FactoryGirl.build(:post, :subject => nil)
    @post.should_not be_valid
  end

  it "doesn't allow a blank subject" do
    @post = FactoryGirl.build(:post, :subject => "")
    @post.should_not be_valid
  end

  it "doesn't allow a subject with only spaces" do
    @post = FactoryGirl.build(:post, :subject => "    ")
    @post.should_not be_valid
  end

  context "recent activity" do
    before(:each) do
      Time.stub(:now => Time.now)
      @post = FactoryGirl.create(:post, :created_at => 1.day.ago)
    end

    it "sets recent activity to post time" do
      @post.recent_activity.to_i.should eq @post.created_at.to_i
    end

    it "sets recent activity to comment time" do
      @comment = FactoryGirl.create(:comment, :post => @post,
          :created_at => 1.hour.ago)
      @post.recent_activity.to_i.should eq @comment.created_at.to_i
    end

    it "shiny new post is recently active" do
      # create a shiny new post
      @post2 = FactoryGirl.create(:post, :created_at => 1.minute.ago)
      Post.recently_active.first.should eq @post2
    end

    it "new comment on old post is recently active" do
      # now comment on an older post
      @comment2 = FactoryGirl.create(:comment, :post => @post, :created_at => 1.second.ago)
      Post.recently_active.first.should eq @post
    end
  end

  context "crop-post association" do
    before {
      @tomato = FactoryGirl.create(:tomato)
      @maize = FactoryGirl.create(:maize)
      @chard = FactoryGirl.create(:chard)
      @post = FactoryGirl.create(:post, :body => "[maize](crop)[tomato](crop)[tomato](crop)")
    }

    it "should be generated without duplicate" do
      @post.crops.should =~ [@tomato, @maize]
      @tomato.posts.should eq [@post]
      @maize.posts.should eq [@post]
    end

    it "should be updated when post was modified" do
      @post.update_attributes(:body => "[chard](crop)")

      @post.crops.should eq [@chard]
      @chard.posts.should eq [@post]
      @tomato.posts.should eq []
      @maize.posts.should eq []
    end

    describe "destroying the post" do
      before do
        @crops = @post.crops
        @post.destroy
      end

      it "shouod delete the association but not the crops" do
        Crop.find_by_id(@tomato.id).should_not eq nil
        Crop.find_by_id(@maize.id).should_not eq nil
        Crop.find_by_id(@tomato.id).posts.should eq []
        Crop.find_by_id(@maize.id).posts.should eq []
      end
    end
  end
end
