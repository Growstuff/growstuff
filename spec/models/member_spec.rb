# frozen_string_literal: true

require 'rails_helper'

describe Member do
  context 'valid member' do
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
      expect(member.comments.size).to == 2
    end

    it "has many forums" do
      create(:forum, owner: member)
      create(:forum, owner: member)
      expect(member.forums.size).to == 2
    end

    it "has many likes" do
      @post1 = create(:post, author: member)
      @post2 = create(:post, author: member)
      @like1 = create(:like, member:, likeable: @post1)
      @like2 = create(:like, member:, likeable: @post2)

      expect(member.likes.length).to eq 2
    end

    it 'has location and lat/long fields' do
      member.update(location: 'Greenwich, UK')
      expect(member.location).to eq 'Greenwich, UK'
      expect(member.latitude.round(2)).to eq 51.48
      expect(member.longitude.round(2)).to eq 0.00
    end

    it 'empties the lat/long if location removed' do
      member.update(location: 'Greenwich, UK')
      member.update(location: '')
      expect(member.location).to eq ''
      expect(member.latitude).to be_nil
      expect(member.longitude).to be_nil
    end

    it 'fails gracefully for unfound locations' do
      member.update(location: 'Tatooine')
      expect(member.location).to eq 'Tatooine'
      expect(member.latitude).to be_nil
      expect(member.longitude).to be_nil
    end
  end

  context 'no TOS agreement' do
    let(:member) { build(:no_tos_member) }

    it "refuses to save a member who hasn't agreed to the TOS" do
      expect(member.save).not_to be(true)
    end
  end

  context 'newsletter scope' do
    it 'finds newsletter recipients' do
      regular_member = create(:member)
      newsletter_member = create(:newsletter_recipient_member)
      expect(Member.wants_newsletter).to include newsletter_member
      expect(Member.wants_newsletter).not_to include regular_member
    end
  end

  context 'same :login_name' do
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

  context 'case sensitivity' do
    it 'preserves case of login name' do
      create(:member, login_name: "BOB")
      expect(Member.find('bob').login_name).to eq 'BOB'
    end
  end

  context 'invalid login names' do
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

  context 'valid login names' do
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

  context 'roles' do
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

  context 'confirmed scope' do
    before do
      create(:member)
      create(:member)
    end

    it 'sees confirmed members' do
      expect(Member.confirmed.size).to == 2
    end

    it 'ignores unconfirmed members' do
      create(:unconfirmed_member)
      expect(Member.confirmed.size).to == 2
    end
  end

  context 'located scope' do
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

  context 'near location' do
    it 'finds nearby members and sorts them' do
      edinburgh_member = create(:edinburgh_member)
      london_member = create(:london_member)
      expect(Member.nearest_to('Greenwich, UK')).to eq [london_member, edinburgh_member]
    end
  end

  describe 'interesting scope' do
    # interesting members are defined as:
    # 1) confirmed
    # 2) have a location
    # 3) have at least one planting
    # 4) ordered by the most recent sign in

    context 'with a few members and plantings' do
      before do
        @members = [
          :london_member, :london_member, :london_member,
          :unconfirmed_member, # !1
          :london_member,      # 1, 2, !3
          :member              # 1, !2, 3
        ].collect { |m| create(m) }

        [0, 1, 2, 3, 5].each do |i|
          create(:planting, owner: @members[i])
        end

        @members[0].updated_at = 3.days.ago
        @members[1].updated_at = 2.days.ago
        @members[2].updated_at = 1.day.ago

        # TODO: Shouldn't this save?

        @result = Member.interesting

        # Some members have multiple plantings, but should only appear once
        create_list(:planting, 3, owner: @members[2])
      end

      it 'finds interesting members without duplicates in the correct order' do
        expect(@result).to eq [@members[2], @members[1], @members[0]]
      end
    end
  end

  context 'harvests' do
    it 'has harvests' do
      member = create(:member)
      harvest = create(:harvest, owner: member)
      expect(member.harvests).to eq [harvest]
    end
  end

  context 'member who followed another member' do
    let(:follower) { create(:member) }
    let(:followed_member) { create(:member) }
    let(:other_member) { create(:member) }

    before do
      @follow = follower.follows.create(follower_id: follower.id, followed_id: followed_member.id)
    end

    context 'already_following' do
      it 'detects that member is already following a member' do
        expect(follower.already_following?(followed_member)).to be true
      end

      it 'detects that member is not already following a member' do
        expect(follower.already_following?(other_member)).to be false
      end
    end

    context 'get_follow' do
      it 'gets the correct follow for a followed member' do
        expect(follower.get_follow(followed_member).id).to eq @follow.id
      end

      it 'returns nil for a member that is not followed' do
        expect(follower.get_follow(other_member)).to be_nil
      end
    end
  end

  context 'subscriptions' do
    let(:member) { create(:member) }
    let(:gb) { instance_double("Gibbon::API.new") }

    it 'subscribes to the newsletter' do
      expect(gb).to receive_message_chain('lists.subscribe')
      member.newsletter_subscribe(gb, true)
    end

    it 'unsubscribes from the newsletter' do
      expect(gb).to receive_message_chain('lists.unsubscribe')
      member.newsletter_unsubscribe(gb, true)
    end
  end

  context 'member deleted' do
    let(:member) { create(:member) }

    context 'queries a scope' do
      before { member.destroy }

      it { expect(Member.all).not_to include(member) }
      it { expect(Member.confirmed).not_to include(member) }
      it { expect(Member.located).not_to include(member) }
      it { expect(Member.recently_signed_in).not_to include(member) }
      it { expect(Member.recently_joined).not_to include(member) }
      it { expect(Member.wants_newsletter).not_to include(member) }
      it { expect(Member.interesting).not_to include(member) }
      it { expect(Member.has_plantings).not_to include(member) }
    end

    it "unsubscribes from mailing list" do
      expect(member).to receive(:newsletter_unsubscribe).and_return(true)
      member.destroy
    end

    context "deleted admin member" do
      let(:member) { create(:admin_member) }

      before { member.discard }

      context 'crop creator' do
        let!(:crop) { create(:crop, creator: member) }

        it "leaves crops behind, reassigned to cropbot" do
          expect(Crop.all).to include(crop)
        end
      end

      context 'forum owners' do
        let!(:forum) { create(:forum, owner: member) }

        it "leaves forums behind, reassigned to ex_admin" do
          expect(forum.owner).to eq(member)
        end
      end
    end
  end
end
