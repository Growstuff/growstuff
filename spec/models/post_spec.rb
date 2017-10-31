require 'rails_helper'

describe Post do
  let(:member) { FactoryBot.create(:member) }
  it_behaves_like "it is likeable"

  it "should be sorted in reverse order" do
    FactoryBot.create(:post,
      subject: 'first entry',
      author: member,
      created_at: 2.days.ago)
    FactoryBot.create(:post,
      subject: 'second entry',
      author: member,
      created_at: 1.day.ago)
    Post.first.subject.should == "second entry"
  end

  it "should have a slug" do
    post = FactoryBot.create(:post, author: member)
    time = post.created_at
    datestr = time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    datestr.size.should eq(4 + time.year.to_s.size)
    post.slug.should eq("#{member.login_name}-#{datestr}-a-post")
  end

  it "has many comments" do
    post = FactoryBot.create(:post, author: member)
    FactoryBot.create(:comment, post: post)
    FactoryBot.create(:comment, post: post)
    post.comments.size.should == 2
  end

  it "supports counting comments" do
    post = FactoryBot.create(:post, author: member)
    FactoryBot.create(:comment, post: post)
    FactoryBot.create(:comment, post: post)
    post.comment_count.should == 2
  end

  it "destroys comments when deleted" do
    post = FactoryBot.create(:post, author: member)
    FactoryBot.create(:comment, post: post)
    FactoryBot.create(:comment, post: post)
    post.comments.size.should eq(2)
    all = Comment.count
    post.destroy
    Comment.count.should eq(all - 2)
  end

  it "belongs to a forum" do
    post = FactoryBot.create(:forum_post)
    post.forum.should be_an_instance_of Forum
  end

  it "doesn't allow a nil subject" do
    post = FactoryBot.build(:post, subject: nil)
    post.should_not be_valid
  end

  it "doesn't allow a blank subject" do
    post = FactoryBot.build(:post, subject: "")
    post.should_not be_valid
  end

  it "doesn't allow a subject with only spaces" do
    post = FactoryBot.build(:post, subject: "    ")
    post.should_not be_valid
  end

  context "recent activity" do
    before do
      Time.stub(now: Time.now)
    end

    let!(:post) { FactoryBot.create(:post, created_at: 1.day.ago) }

    it "sets recent activity to post time" do
      post.recent_activity.to_i.should eq post.created_at.to_i
    end

    it "sets recent activity to comment time" do
      comment = FactoryBot.create(:comment, post: post,
                                             created_at: 1.hour.ago)
      post.recent_activity.to_i.should eq comment.created_at.to_i
    end

    it "shiny new post is recently active" do
      # create a shiny new post
      post2 = FactoryBot.create(:post, created_at: 1.minute.ago)
      Post.recently_active.first.should eq post2
      Post.recently_active.second.should eq post
    end

    it "new comment on old post is recently active" do
      # now comment on an older post
      post2 = FactoryBot.create(:post, created_at: 1.minute.ago)
      FactoryBot.create(:comment, post: post, created_at: 1.second.ago)
      Post.recently_active.first.should eq post
      Post.recently_active.second.should eq post2
    end
  end

  context "notifications" do
    let(:member2) { FactoryBot.create(:member) }

    it "sends a notification when a member is mentioned using @-syntax" do
      expect {
        FactoryBot.create(:post, author: member, body: "Hey @#{member2}")
      }.to change(Notification, :count).by(1)
    end

    it "sends a notification when a member is mentioned using [](member) syntax" do
      expect {
        FactoryBot.create(:post, author: member, body: "Hey [#{member2}](member)")
      }.to change(Notification, :count).by(1)
    end

    it "sets the notification field" do
      p = FactoryBot.create(:post, author: member, body: "Hey @#{member2}")
      n = Notification.first
      n.sender.should eq member
      n.recipient.should eq member2
      n.subject.should match(/mentioned you in their post/)
      n.body.should eq p.body
    end

    it "sends notifications to all members mentioned" do
      member3 = FactoryBot.create(:member)
      expect {
        FactoryBot.create(:post, author: member, body: "Hey @#{member2} & @#{member3}")
      }.to change(Notification, :count).by(2)
    end

    it "doesn't send notifications if you mention yourself" do
      expect {
        FactoryBot.create(:post, author: member, body: "@#{member}")
      }.to change(Notification, :count).by(0)
    end
  end

  context "crop-post association" do
    let!(:tomato) { FactoryBot.create(:tomato) }
    let!(:maize) { FactoryBot.create(:maize) }
    let!(:chard) { FactoryBot.create(:chard) }
    let!(:post) { FactoryBot.create(:post, body: "[maize](crop)[tomato](crop)[tomato](crop)") }

    it "should be generated" do
      expect(tomato.posts).to eq [post]
      expect(maize.posts).to eq [post]
    end

    it "should not duplicate" do
      expect(post.crops) =~ [tomato, maize]
    end

    it "should be updated when post was modified" do
      post.update_attributes(body: "[chard](crop)")

      expect(post.crops).to eq [chard]
      expect(chard.posts).to eq [post]
      expect(tomato.posts).to eq []
      expect(maize.posts).to eq []
    end

    describe "destroying the post" do
      before do
        post.destroy
      end

      it "should delete the association" do
        expect(Crop.find(tomato.id).posts).to eq []
        expect(Crop.find(maize.id).posts).to eq []
      end

      it "should not delete the crops" do
        expect(Crop.find(tomato.id)).to_not eq nil
        expect(Crop.find(maize.id)).to_not eq nil
      end
    end
  end

  it 'excludes deleted members' do
    post = FactoryBot.create :post, author: member
    expect(Post.joins(:author).all).to include(post)
    member.destroy
    expect(Post.joins(:author).all).not_to include(post)
  end
end
