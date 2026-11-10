# frozen_string_literal: true

require 'rails_helper'

describe Member do
  context 'with a valid member' do
    let!(:member) { create(:member, login_name: 'hinemoa') }

    describe 'should be fetchable from the database' do
      subject { Member.find(member.id) }

      it { is_expected.to be_an_instance_of Member }
      it { expect(subject.encrypted_password).not_to be_nil }
    end

    describe 'should have a friendly slug' do
      it { expect(member.slug).to eq('hinemoa') }
    end

    it 'has a bio' do
      member.bio = 'I love seeds'
      expect(member.bio).to eq 'I love seeds'
    end

    it 'has a default garden' do
      expect(member.gardens.count).to eq 1
    end

    it "doesn't show email by default" do
      expect(member.show_email).to be false
    end

    it 'stringifies as the login_name' do
      expect(member.to_s).to eq 'hinemoa'
    end

    it 'is able to fetch posts' do
      post = create(:post, author: member)
      expect(member.posts).to eq [post]
    end

    it 'is able to fetch gardens' do
      expect(member.gardens.first.name).to eq "Garden"
    end

    it 'has many plantings' do
      create(:planting, owner: member)
      expect(member.plantings.size).to eq 1
    end

    it "has many comments" do
      create(:comment, author: member)
      create(:comment, author: member)
      expect(member.comments.size).to eq 2
    end

    it "has many forums" do
      create(:forum, owner: member)
      create(:forum, owner: member)
      expect(member.forums.size).to eq 2
    end

    it "has many likes" do
      @post1 = create(:post, author: member)
      @post2 = create(:post, author: member)
      @like1 = create(:like, member:, likeable: @post1)
      @like2 = create(:like, member:, likeable: @post2)

      expect(member.likes.length).to eq 2
    end

    context 'with a location' do
      before { member.update(location: 'Greenwich, UK') }

      it { expect(member.location).to eq 'Greenwich, UK' }
      it { expect(member.latitude.round(2)).to eq 51.48 }
      it { expect(member.longitude.round(2)).to eq 0.00 }

      context 'when the location is removed' do
        before { member.update(location: '') }

        it { expect(member.location).to eq '' }
        it { expect(member.latitude).to be_nil }
        it { expect(member.longitude).to be_nil }
      end
    end

    context 'with an unfound location' do
      before { member.update(location: 'Tatooine') }

      it { expect(member.location).to eq 'Tatooine' }
      it { expect(member.latitude).to be_nil }
      it { expect(member.longitude).to be_nil }
    end
  end

  context 'without a TOS agreement' do
    let(:member) { build(:no_tos_member) }

    it "refuses to save a member who hasn't agreed to the TOS" do
      expect(member.save).not_to be(true)
    end
  end

  context 'with the same login name' do
    it "does not allow two members with the same login_name" do
      create(:member, login_name: "bob")
      member = build(:member, login_name: "bob")
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("has already been taken")
    end

    it "tests uniqueness case-insensitively" do
      create(:member, login_name: "bob")
      member = build(:member, login_name: "BoB")
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("has already been taken")
    end
  end

  describe 'case sensitivity' do
    it 'preserves case of login name' do
      create(:member, login_name: "BOB")
      expect(Member.find('bob').login_name).to eq 'BOB'
    end
  end

  context 'with invalid login names' do
    it "doesn't allow short names" do
      member = build(:invalid_member_shortname)
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("should be between 2 and 25 characters long")
    end

    it "doesn't allow really long names" do
      member = build(:invalid_member_longname)
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("should be between 2 and 25 characters long")
    end

    it "doesn't allow spaces in names" do
      member = build(:invalid_member_spaces)
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("may only include letters, numbers, or underscores")
    end

    it "doesn't allow other chars in names" do
      member = build(:invalid_member_badchars)
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("may only include letters, numbers, or underscores")
    end

    it "doesn't allow reserved names" do
      member = build(:invalid_member_badname)
      expect(member).not_to be_valid
      expect(member.errors[:login_name]).to include("name is reserved")
    end
  end

  context 'with valid login names' do
    it "allows plain alphanumeric chars in names" do
      member = build(:valid_member_alphanumeric)
      expect(member).to be_valid
    end

    it "allows uppercase chars in names" do
      member = build(:valid_member_uppercase)
      expect(member).to be_valid
    end

    it "allows underscores in names" do
      member = build(:valid_member_underscore)
      expect(member).to be_valid
    end
  end

  describe 'roles' do
    let(:member) { create(:member) }
    let(:role)   { create(:role)   }

    before do
      member.roles << role
    end

    it 'has a role' do
      expect(member.roles.first).to eq role
      expect(member.role?(:moderator)).to be true
    end

    it 'sets up roles in factories' do
      admin = create(:admin_member)
      expect(admin.role?(:admin)).to be true
    end

    it 'converts role names properly' do
      # need to make sure spaces get turned to underscores
      role = create(:role, name: "a b c")
      member.roles << role
      expect(member.role?(:a_b_c)).to be true
    end
  end

  describe 'confirmed scope' do
    before do
      create(:member)
      create(:member)
    end

    it 'sees confirmed members' do
      expect(Member.confirmed.size).to eq 2
    end

    it 'ignores unconfirmed members' do
      create(:unconfirmed_member)
      expect(Member.confirmed.size).to eq 2
    end
  end

  describe 'located scope' do
    # located members must have location, lat, long
    it 'finds members who have locations' do
      london_member = create(:london_member)
      expect(Member.located).to include london_member
    end

    it 'ignores members with blank locations' do
      nowhere_member = create(:member)
      expect(Member.located).not_to include nowhere_member
    end

    it 'ignores members with blank lat/long' do
      london_member = create(:london_member)
      london_member.latitude = nil
      london_member.longitude = nil
      london_member.save(validate: false)
      expect(Member.located).not_to include london_member
    end
  end

  context 'when near a location' do
    it 'finds nearby members and sorts them' do
      edinburgh_member = create(:edinburgh_member)
      london_member = create(:london_member)
      expect(Member.nearest_to('Greenwich, UK')).to eq [london_member, edinburgh_member]
    end

    it 'leaves out members who have been deleted' do
      edinburgh_member = create(:edinburgh_member)
      create(:london_member).discard
      expect(Member.nearest_to('Greenwich, UK')).to eq [edinburgh_member]
    end

    it 'returns Member.none when place is blank or un-geocoded' do
      expect(Member.nearest_to('')).to eq Member.none
      expect(Member.nearest_to(nil)).to eq Member.none
    end

    it 'respects the limit parameter' do
      create(:edinburgh_member)
      create(:london_member)
      expect(Member.nearest_to('Greenwich, UK', 1).to_a.size).to eq 1
    end
  end

  describe 'harvests' do
    it 'has harvests' do
      member = create(:member)
      harvest = create(:harvest, owner: member)
      expect(member.harvests).to eq [harvest]
    end
  end

  context 'when the member followed another member' do
    let(:follower) { create(:member) }
    let(:followed_member) { create(:member) }
    let(:other_member) { create(:member) }

    before do
      @follow = follower.follows.create(follower_id: follower.id, followed_id: followed_member.id)
    end

    describe 'already_following' do
      it 'detects that member is already following a member' do
        expect(follower.already_following?(followed_member)).to be true
      end

      it 'detects that member is not already following a member' do
        expect(follower.already_following?(other_member)).to be false
      end
    end

    describe 'get_follow' do
      it 'gets the correct follow for a followed member' do
        expect(follower.get_follow(followed_member).id).to eq @follow.id
      end

      it 'returns nil for a member that is not followed' do
        expect(follower.get_follow(other_member)).to be_nil
      end
    end
  end

  context 'when the member is deleted' do
    let(:member) { create(:member) }

    context 'when querying a scope' do
      before { member.destroy }

      it { expect(Member.all).not_to include(member) }
      it { expect(Member.confirmed).not_to include(member) }
      it { expect(Member.located).not_to include(member) }
      it { expect(Member.recently_signed_in).not_to include(member) }
      it { expect(Member.recently_joined).not_to include(member) }
      it { expect(Member.has_plantings).not_to include(member) }
    end

    context "with a deleted admin member" do
      let(:member) { create(:admin_member) }

      before { member.discard }

      context 'when the member is the crop creator' do
        let!(:crop) { create(:crop, creator: member) }

        it "leaves crops behind, reassigned to cropbot" do
          expect(Crop.all).to include(crop)
        end
      end

      context 'when the member is a forum owner' do
        let!(:forum) { create(:forum, owner: member) }

        it "leaves forums behind, reassigned to ex_admin" do
          expect(forum.owner).to eq(member)
        end
      end
    end
  end

  describe '#nursery' do
    let(:member) { create(:member) }

    it 'makes a nursery garden' do
      expect(member.nursery!).to have_attributes(nursery: true, owner: member, name: 'Nursery')
    end

    it 'returns the same nursery each time' do
      first = member.nursery!
      expect(member.nursery!).to eq first
    end

    it 'makes only one nursery' do
      2.times { member.nursery! }
      expect(member.gardens.nurseries.count).to eq 1
    end

    it 'does not count the nursery as a second garden' do
      member.nursery!
      expect(member.has_activity?).to be false
    end

    context 'when a garden is already called Nursery' do
      before { create(:garden, owner: member, name: 'Nursery') }

      it 'picks another name' do
        expect(member.nursery!.name).to eq 'Nursery 2'
      end
    end
  end

  describe '#located_place' do
    subject(:place) { member.located_place }

    let(:member) { build(:member, location: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772) }

    it { is_expected.to eq(name: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772) }

    context 'without coordinates' do
      let(:member) { build(:member, location: 'Wellington, New Zealand', latitude: nil, longitude: nil) }

      it { is_expected.to be_nil }
    end

    context 'without a location' do
      let(:member) { build(:member, location: '', latitude: -41.2887, longitude: 174.7772) }

      it { is_expected.to be_nil }
    end
  end

  describe '#ban! and #banned?' do
    let(:member) { create(:member) }

    it 'marks the member as banned' do
      member.ban!
      expect(member.banned?).to be true
    end
  end

  describe '#update_spam_score!' do
    let(:member) { create(:member) }

    context 'when spam score reaches the ban threshold' do
      before do
        allow(UserBehaviourDetectionService).to receive(:score_for).with(member).and_return(75)
      end

      it 'updates the spam score' do
        expect { member.update_spam_score! }.to change { member.reload.spam_score }.to(75)
      end

      it 'bans the member' do
        expect { member.update_spam_score! }.to change { member.reload.banned? }.from(false).to(true)
      end
    end

    context 'when spam score is above the ban threshold' do
      before do
        allow(UserBehaviourDetectionService).to receive(:score_for).with(member).and_return(100)
      end

      it 'updates the spam score' do
        expect { member.update_spam_score! }.to change { member.reload.spam_score }.to(100)
      end

      it 'bans the member' do
        expect { member.update_spam_score! }.to change { member.reload.banned? }.from(false).to(true)
      end
    end

    context 'when spam score is below the ban threshold' do
      before do
        allow(UserBehaviourDetectionService).to receive(:score_for).with(member).and_return(74)
      end

      it 'updates the spam score' do
        expect { member.update_spam_score! }.to change { member.reload.spam_score }.to(74)
      end

      it 'does not ban the member' do
        member.update_spam_score!
        expect(member.reload.banned?).to be false
      end
    end
  end

  describe 'email' do
    it 'stores a blank email as NULL so several members can have none' do
      member = build(:member, email: '  ')

      expect(member.email).to be_nil
    end
  end

  describe '#locale' do
    subject(:member) { build(:member) }

    it 'defaults to nil' do
      expect(member.locale).to be_nil
    end

    it 'persists a valid locale in settings' do
      member.locale = 'es'
      expect(member.settings['locale']).to eq 'es'
    end

    it 'returns the saved locale' do
      member.locale = 'es'
      expect(member.locale).to eq 'es'
    end

    it 'removes locale from settings when set to blank' do
      member.locale = 'es'
      member.locale = ''
      expect(member.settings['locale']).to be_nil
    end

    it 'allows valid locales' do
      member.locale = 'fr'
      expect(member).to be_valid
    end

    it 'rejects unsupported locales' do
      member.settings = { 'locale' => 'invalid_lang' }
      expect(member).not_to be_valid
    end
  end
end
