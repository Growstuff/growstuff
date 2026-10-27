# frozen_string_literal: true

require 'rails_helper'

describe Post do
  let(:member) { create(:member, login_name: 'whinacooper') }

  it_behaves_like "it is likeable"

  it "has a slug" do
    post = create(:post, author: member, subject: 'A Post')
    time = post.created_at
    datestr = time.strftime("%Y%m%d")
    # 2 digit day and month, full-length years
    # Counting digits using Math.log is not precise enough!
    datestr.size.should eq(4 + time.year.to_s.size)
    post.slug.should eq("#{member.login_name}-#{datestr}-a-post")
  end

  it "has many comments" do
    post = create(:post, author: member)
    create(:comment, commentable: post)
    create(:comment, commentable: post)
    post.comments.size.should == 2
  end

  it "supports counting comments" do
    post = create(:post, author: member)
    create(:comment, commentable: post)
    create(:comment, commentable: post)
    post.comment_count.should == 2
  end

  it "destroys comments when deleted" do
    post = create(:post, author: member)
    create(:comment, commentable: post)
    create(:comment, commentable: post)
    post.comments.size.should eq(2)
    all = Comment.count
    post.destroy
    Comment.count.should eq(all - 2)
  end

  it "belongs to a forum" do
    post = create(:forum_post)
    post.forum.should be_an_instance_of Forum
  end

  it "doesn't allow a nil subject" do
    post = build(:post, subject: nil)
    post.should_not be_valid
  end

  it "doesn't allow a blank subject" do
    post = build(:post, subject: "")
    post.should_not be_valid
  end

  it "doesn't allow a subject with only spaces" do
    post = build(:post, subject: "    ")
    post.should_not be_valid
  end

  context "recent activity" do
    before do
      Time.stub(now: Time.zone.now)
    end

    let!(:post) { create(:post, created_at: 1.day.ago) }

    it "sets recent activity to post time" do
      post.recent_activity.to_i.should eq post.created_at.to_i
    end

    it "sets recent activity to comment time" do
      comment = create(:comment, commentable: post,
                                 created_at:  1.hour.ago)
      post.recent_activity.to_i.should eq comment.created_at.to_i
    end

    it "shiny new post is recently active" do
      # create a shiny new post
      post2 = create(:post, created_at: 1.minute.ago)
      described_class.recently_active.first.should eq post2
      described_class.recently_active.second.should eq post
    end

    it "new comment on old post is recently active" do
      # now comment on an older post
      post2 = create(:post, created_at: 1.minute.ago)
      create(:comment, commentable: post, created_at: 1.second.ago)
      described_class.recently_active.first.should eq post
      described_class.recently_active.second.should eq post2
    end
  end

  context "notifications" do
    let(:member2) { create(:member) }

    it "sends a notification when a member is mentioned using @-syntax" do
      expect do
        create(:post, author: member, body: "Hey @#{member2}")
      end.to change(Notification, :count).by(1)
    end

    it "sends a notification when a member is mentioned using [](member) syntax" do
      expect do
        create(:post, author: member, body: "Hey [#{member2}](member)")
      end.to change(Notification, :count).by(1)
    end

    it "sets the notification field" do
      p = create(:post, author: member, body: "Hey @#{member2}")
      n = Notification.first
      n.sender.should eq member
      n.recipient.should eq member2
      n.subject.should match(/mentioned you in their post/)
      n.body.should eq p.body
    end

    it "sends notifications to all members mentioned" do
      member3 = create(:member)
      expect do
        create(:post, author: member, body: "Hey @#{member2} & @#{member3}")
      end.to change(Notification, :count).by(2)
    end

    it "doesn't send notifications if you mention yourself" do
      expect do
        create(:post, author: member, body: "@#{member}")
      end.not_to change(Notification, :count)
    end
  end

  context "crop-post association" do
    let!(:tomato) { create(:tomato) }
    let!(:maize) { create(:maize)                                                   }
    let!(:chard) { create(:chard)                                                   }
    let!(:post)  { create(:post, body: "[maize](crop)[tomato](crop)[tomato](crop)") }

    it "is generated" do
      expect(tomato.posts).to eq [post]
      expect(maize.posts).to eq [post]
    end

    it "does not duplicate" do
      expect(post.crops).to match_array([tomato, maize])
    end

    it "is updated when post was modified" do
      post.update(body: "[chard](crop)")

      expect(post.crops).to eq [chard]
      expect(chard.posts).to eq [post]
      expect(tomato.posts).to eq []
      expect(maize.posts).to eq []
    end

    describe "destroying the post" do
      before do
        post.destroy
      end

      it "deletes the association" do
        expect(Crop.find(tomato.id).posts).to eq []
        expect(Crop.find(maize.id).posts).to eq []
      end

      it "does not delete the crops" do
        expect(Crop.find(tomato.id)).not_to be_nil
        expect(Crop.find(maize.id)).not_to be_nil
      end
    end
  end

  it 'excludes deleted members' do
    post = create(:post, author: member)
    expect(described_class.joins(:author).all).to include(post)
    member.destroy
    expect(described_class.joins(:author).all).not_to include(post)
  end

  describe '#default_photo' do
    subject { post.default_photo }

    let(:post) { create(:post, author: member) }
    let(:liked) { create(:photo, owner: member, likes_count: 5) }
    let(:chosen) { create(:photo, owner: member) }

    before do
      post.photos << liked
      post.photos << chosen
    end

    context 'without a card photo' do
      it { is_expected.to eq liked }
    end

    context 'with a card photo' do
      before { post.update!(card_photo: chosen) }

      it { is_expected.to eq chosen }
    end
  end

  describe 'card photo validation' do
    subject(:post) { build(:post, author: member, card_photo: photo) }

    context 'when the photo is not in the post' do
      let(:photo) { create(:photo, owner: member) }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#read_time_minutes' do
    subject { build(:post, body: ('word ' * words)).read_time_minutes }

    context 'with a short body' do
      let(:words) { 10 }

      it { is_expected.to eq 1 }
    end

    context 'with a long body' do
      let(:words) { 450 }

      it { is_expected.to eq 3 }
    end
  end

  describe '#more_from_author' do
    subject { post.more_from_author }

    let(:post) { create(:post, author: member) }
    let!(:other) { create(:post, author: member) }

    before { create(:post) }

    it { is_expected.to eq [other] }
  end

  describe 'drafts' do
    let(:draft) { create(:post, author: member, draft: true) }

    it 'has no published date' do
      expect(draft.published_at).to be_nil
    end

    it 'is a draft' do
      expect(draft).to be_draft
    end

    it 'is left out of the default scope' do
      draft
      expect(described_class.all).not_to include draft
    end

    it 'is found with drafts' do
      expect(described_class.with_drafts).to include draft
    end

    context 'when published' do
      before { draft.update!(draft: false) }

      it { expect(draft).to be_published }
    end

    context 'when saved again as a draft' do
      before { draft.update!(subject: 'New subject', draft: true) }

      it { expect(draft).to be_draft }
    end

    context 'when saved with no draft setting' do
      before { draft.update!(subject: 'New subject') }

      it { expect(draft).to be_draft }
    end

    it 'does not notify mentioned members' do
      mentioned = create(:member)
      create(:post, author: member, draft: true, body: "hello @#{mentioned.login_name}")
      expect(Notification.where(recipient: mentioned)).to be_empty
    end

    it 'notifies mentioned members once it is published' do
      mentioned = create(:member)
      create(:post, author: member, draft: true, body: "hello @#{mentioned.login_name}").update!(draft: false)
      expect(Notification.where(recipient: mentioned).count).to eq 1
    end
  end
end
