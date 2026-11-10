# frozen_string_literal: true

require 'rails_helper'

describe Post do
  let(:member) { create(:member, login_name: 'whinacooper') }

  it_behaves_like "it is likeable"

  describe "slug" do
    let(:post) { create(:post, author: member, subject: 'A Post') }
    let(:datestr) { post.created_at.strftime("%Y%m%d") }

    # 2 digit day and month, full-length years
    it "dates with a full-length year" do
      expect(datestr.size).to eq(4 + post.created_at.year.to_s.size)
    end

    it "is the login name, date and subject" do
      expect(post.slug).to eq("#{member.login_name}-#{datestr}-a-post")
    end
  end

  it "has many comments" do
    post = create(:post, author: member)
    create(:comment, commentable: post)
    create(:comment, commentable: post)
    expect(post.comments.size).to eq 2
  end

  it "supports counting comments" do
    post = create(:post, author: member)
    create(:comment, commentable: post)
    create(:comment, commentable: post)
    expect(post.comment_count).to eq 2
  end

  describe "when deleted" do
    let(:post) { create(:post, author: member) }

    before { create_list(:comment, 2, commentable: post) }

    it "destroys its comments" do
      expect { post.destroy }.to change(Comment, :count).by(-2)
    end
  end

  it "belongs to a forum" do
    post = create(:forum_post)
    expect(post.forum).to be_an_instance_of Forum
  end

  it "doesn't allow a nil subject" do
    post = build(:post, subject: nil)
    expect(post).not_to be_valid
  end

  it "doesn't allow a blank subject" do
    post = build(:post, subject: "")
    expect(post).not_to be_valid
  end

  it "doesn't allow a subject with only spaces" do
    post = build(:post, subject: "    ")
    expect(post).not_to be_valid
  end

  describe "recent activity" do
    before do
      Time.stub(now: Time.zone.now)
    end

    let!(:post) { create(:post, created_at: 1.day.ago) }

    it "sets recent activity to post time" do
      expect(post.recent_activity.to_i).to eq post.created_at.to_i
    end

    it "sets recent activity to comment time" do
      comment = create(:comment, commentable: post,
                                 created_at:  1.hour.ago)
      expect(post.recent_activity.to_i).to eq comment.created_at.to_i
    end

    let!(:post2) { create(:post, created_at: 1.minute.ago) }

    context "with a shiny new post" do
      it("lists it first") { expect(described_class.recently_active.first).to eq post2 }
      it("lists the older post second") { expect(described_class.recently_active.second).to eq post }
    end

    context "with a new comment on the old post" do
      before { create(:comment, commentable: post, created_at: 1.second.ago) }

      it("lists the old post first") { expect(described_class.recently_active.first).to eq post }
      it("lists the newer post second") { expect(described_class.recently_active.second).to eq post2 }
    end
  end

  describe "notifications" do
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

    describe "the notification" do
      let!(:post) { create(:post, author: member, body: "Hey @#{member2}") }
      let(:notification) { Notification.first }

      it { expect(notification.sender).to eq member }
      it { expect(notification.recipient).to eq member2 }
      it { expect(notification.subject).to match(/mentioned you in their post/) }
      it { expect(notification.body).to eq post.body }
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

  context "with a crop-post association" do
    let!(:tomato) { create(:tomato) }
    let!(:maize) { create(:maize)                                                   }
    let!(:chard) { create(:chard)                                                   }
    let!(:post)  { create(:post, body: "[maize](crop)[tomato](crop)[tomato](crop)") }

    it("is generated for the first crop") { expect(tomato.posts).to eq [post] }
    it("is generated for the second crop") { expect(maize.posts).to eq [post] }

    it "does not duplicate" do
      expect(post.crops).to match_array([tomato, maize])
    end

    context "when the post is modified" do
      before { post.update(body: "[chard](crop)") }

      it("links the post to the new crop") { expect(post.crops).to eq [chard] }
      it("links the new crop to the post") { expect(chard.posts).to eq [post] }
      it("unlinks a removed crop") { expect(tomato.posts).to eq [] }
      it("unlinks another removed crop") { expect(maize.posts).to eq [] }
    end

    describe "destroying the post" do
      before do
        post.destroy
      end

      it("deletes the association with the first crop") { expect(Crop.find(tomato.id).posts).to eq [] }
      it("deletes the association with the second crop") { expect(Crop.find(maize.id).posts).to eq [] }
      it("does not delete the crops") { expect(Crop.where(id: [tomato.id, maize.id]).count).to eq 2 }
    end
  end

  describe 'joining the author' do
    let!(:post) { create(:post, author: member) }

    it('includes the post of a current member') { expect(described_class.joins(:author).all).to include(post) }

    it 'excludes the post of a deleted member' do
      member.destroy
      expect(described_class.joins(:author).all).not_to include(post)
    end
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

    context 'when saved blank' do
      subject(:blank) { build(:post, author: member, subject: '', body: '', draft: true) }

      it { is_expected.to be_valid }
    end

    context 'when published blank' do
      subject(:blank) { build(:post, author: member, subject: '', body: '', draft: false) }

      it { is_expected.not_to be_valid }
    end

    context 'when a blank draft is published' do
      before { draft.update(subject: '', body: '', draft: true) }

      it 'is rejected' do
        expect(draft.update(draft: false)).to be false
      end
    end

    context 'when its title changes' do
      before { draft.update!(subject: 'A better title', draft: true) }

      it 'follows the title in its address' do
        expect(draft.slug).to end_with 'a-better-title'
      end
    end

    context 'when published and its title changes' do
      let(:post) { create(:post, author: member) }

      before { post.update!(subject: 'Something else') }

      it 'keeps its address' do
        expect { post.reload }.not_to change(post, :slug)
      end
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

  describe 'updating author spam score' do
    let(:member) { create(:member) }

    it 'triggers update_spam_score! on author after save' do
      expect(member).to receive(:update_spam_score!)
      create(:post, author: member)
    end
  end
end
