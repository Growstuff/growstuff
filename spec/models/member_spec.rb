require 'rails_helper'

describe 'member' do
  context 'valid member' do
    let(:member) { FactoryBot.create(:member) }

    it 'should be fetchable from the database' do
      member2 = Member.find(member.id)
      member2.should be_an_instance_of Member
      member2.login_name.should match(/member\d+/)
      member2.encrypted_password.should_not be_nil
    end

    it 'should have a friendly slug' do
      member.slug.should match(/member\d+/)
    end

    it 'has a bio' do
      member.bio = 'I love seeds'
      member.bio.should eq 'I love seeds'
    end

    it 'should have a default garden' do
      member.gardens.size.should == 1
    end

    it "doesn't show email by default" do
      member.show_email.should be(false)
    end

    it 'should stringify as the login_name' do
      member.to_s.should match(/member\d+/)
      member.to_s.should match(/member\d+/)
    end

    it 'should be able to fetch posts' do
      post = FactoryBot.create(:post, author: member)
      member.posts.should eq [post]
    end

    it 'should be able to fetch gardens' do
      member.gardens.first.name.should eq "Garden"
    end

    it 'has many plantings' do
      FactoryBot.create(:planting, owner: member)
      member.plantings.size.should eq 1
    end

    it "has many comments" do
      FactoryBot.create(:comment, author: member)
      FactoryBot.create(:comment, author: member)
      member.comments.size.should == 2
    end

    it "has many forums" do
      FactoryBot.create(:forum, owner: member)
      FactoryBot.create(:forum, owner: member)
      member.forums.size.should == 2
    end

    it "has many likes" do
      @post1 = FactoryBot.create(:post, author: member)
      @post2 = FactoryBot.create(:post, author: member)
      @like1 = FactoryBot.create(:like, member: member, likeable: @post1)
      @like2 = FactoryBot.create(:like, member: member, likeable: @post2)

      expect(member.likes.length).to eq 2
    end

    it 'has location and lat/long fields' do
      member.update_attributes(location: 'Greenwich, UK')
      member.location.should eq 'Greenwich, UK'
      member.latitude.round(2).should eq 51.48
      member.longitude.round(2).should eq 0.00
    end

    it 'empties the lat/long if location removed' do
      member.update_attributes(location: 'Greenwich, UK')
      member.update_attributes(location: '')
      member.location.should eq ''
      member.latitude.should be_nil
      member.longitude.should be_nil
    end

    it 'fails gracefully for unfound locations' do
      member.update_attributes(location: 'Tatooine')
      member.location.should eq 'Tatooine'
      member.latitude.should be_nil
      member.longitude.should be_nil
    end
  end

  context 'no TOS agreement' do
    let(:member) { FactoryBot.build(:no_tos_member) }

    it "should refuse to save a member who hasn't agreed to the TOS" do
      member.save.should_not be(true)
    end
  end

  context 'newsletter scope' do
    it 'finds newsletter recipients' do
      member1 = FactoryBot.create(:member)
      member2 = FactoryBot.create(:newsletter_recipient_member)
      Member.wants_newsletter.should include member2
      Member.wants_newsletter.should_not include member1
    end
  end

  context 'same :login_name' do
    it "should not allow two members with the same login_name" do
      FactoryBot.create(:member, login_name: "bob")
      member = FactoryBot.build(:member, login_name: "bob")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end

    it "tests uniqueness case-insensitively" do
      FactoryBot.create(:member, login_name: "bob")
      member = FactoryBot.build(:member, login_name: "BoB")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end
  end

  context 'case sensitivity' do
    it 'preserves case of login name' do
      FactoryBot.create(:member, login_name: "BOB")
      Member.find('bob').login_name.should eq 'BOB'
    end
  end

  context 'invalid login names' do
    it "doesn't allow short names" do
      member = FactoryBot.build(:invalid_member_shortname)
      member.should_not be_valid
      member.errors[:login_name].should include("should be between 2 and 25 characters long")
    end
    it "doesn't allow really long names" do
      member = FactoryBot.build(:invalid_member_longname)
      member.should_not be_valid
      member.errors[:login_name].should include("should be between 2 and 25 characters long")
    end
    it "doesn't allow spaces in names" do
      member = FactoryBot.build(:invalid_member_spaces)
      member.should_not be_valid
      member.errors[:login_name].should include("may only include letters, numbers, or underscores")
    end
    it "doesn't allow other chars in names" do
      member = FactoryBot.build(:invalid_member_badchars)
      member.should_not be_valid
      member.errors[:login_name].should include("may only include letters, numbers, or underscores")
    end
    it "doesn't allow reserved names" do
      member = FactoryBot.build(:invalid_member_badname)
      member.should_not be_valid
      member.errors[:login_name].should include("name is reserved")
    end
  end

  context 'valid login names' do
    it "allows plain alphanumeric chars in names" do
      member = FactoryBot.build(:valid_member_alphanumeric)
      member.should be_valid
    end
    it "allows uppercase chars in names" do
      member = FactoryBot.build(:valid_member_uppercase)
      member.should be_valid
    end
    it "allows underscores in names" do
      member = FactoryBot.build(:valid_member_underscore)
      member.should be_valid
    end
  end

  context 'roles' do
    let(:member) { FactoryBot.create(:member) }
    let(:role) { FactoryBot.create(:role) }

    before do
      member.roles << role
    end

    it 'has a role' do
      member.roles.first.should eq role
      member.role?(:moderator).should eq true
    end

    it 'sets up roles in factories' do
      admin = FactoryBot.create(:admin_member)
      admin.role?(:admin).should eq true
    end

    it 'converts role names properly' do
      # need to make sure spaces get turned to underscores
      role = FactoryBot.create(:role, name: "a b c")
      member.roles << role
      member.role?(:a_b_c).should eq true
    end
  end

  context 'confirmed scope' do
    before(:each) do
      FactoryBot.create(:member)
      FactoryBot.create(:member)
    end

    it 'sees confirmed members' do
      Member.confirmed.size.should == 2
    end

    it 'ignores unconfirmed members' do
      FactoryBot.create(:unconfirmed_member)
      Member.confirmed.size.should == 2
    end
  end

  context 'located scope' do
    # located members must have location, lat, long
    it 'finds members who have locations' do
      london_member = FactoryBot.create(:london_member)
      Member.located.should include london_member
    end

    it 'ignores members with blank locations' do
      nowhere_member = FactoryBot.create(:member)
      Member.located.should_not include nowhere_member
    end

    it 'ignores members with blank lat/long' do
      london_member = FactoryBot.create(:london_member)
      london_member.latitude = nil
      london_member.longitude = nil
      london_member.save(validate: false)
      Member.located.should_not include london_member
    end
  end

  context 'near location' do
    it 'finds nearby members and sorts them' do
      edinburgh_member = FactoryBot.create(:edinburgh_member)
      london_member = FactoryBot.create(:london_member)
      Member.nearest_to('Greenwich, UK').should eq [london_member, edinburgh_member]
    end
  end

  describe 'interesting scope' do
    # interesting members are defined as:
    # 1) confirmed
    # 2) have a location
    # 3) have at least one planting
    # 4) ordered by the most recent sign in

    context 'with a few members and plantings' do
      before :each do
        @members = [
          :london_member, :london_member, :london_member,
          :unconfirmed_member, # !1
          :london_member,      # 1, 2, !3
          :member              # 1, !2, 3
        ].collect { |m| FactoryBot.create(m) }

        [0, 1, 2, 3, 5].each do |i|
          FactoryBot.create(:planting, owner: @members[i])
        end

        @members[0].updated_at = 3.days.ago
        @members[1].updated_at = 2.days.ago
        @members[2].updated_at = 1.day.ago

        # TODO: Shouldn't this save?

        @result = Member.interesting

        # Some members have multiple plantings, but should only appear once
        3.times do
          FactoryBot.create(:planting, owner: @members[2])
        end
      end

      it 'finds interesting members without duplicates in the correct order' do
        @result.should eq [@members[2], @members[1], @members[0]]
      end
    end
  end

  context 'harvests' do
    it 'has harvests' do
      member = FactoryBot.create(:member)
      harvest = FactoryBot.create(:harvest, owner: member)
      member.harvests.should eq [harvest]
    end
  end

  context 'member who followed another member' do
    let(:member1) { FactoryBot.create(:member) }
    let(:member2) { FactoryBot.create(:member) }
    let(:member3) { FactoryBot.create(:member) }

    before do
      @follow = member1.follows.create(follower_id: member1.id, followed_id: member2.id)
    end

    context 'already_following' do
      it 'detects that member is already following a member' do
        expect(member1.already_following?(member2)).to eq true
      end

      it 'detects that member is not already following a member' do
        expect(member1.already_following?(member3)).to eq false
      end
    end

    context 'get_follow' do
      it 'gets the correct follow for a followed member' do
        expect(member1.get_follow(member2).id).to eq @follow.id
      end

      it 'returns nil for a member that is not followed' do
        expect(member1.get_follow(member3)).to be_nil
      end
    end
  end

  context 'subscriptions' do
    let(:member) { FactoryBot.create(:member) }
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
    let(:member) { FactoryBot.create(:member) }

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
      let(:member) { FactoryBot.create(:admin_member) }

      before { member.destroy }

      context 'crop creator' do
        let!(:crop) { FactoryBot.create(:crop, creator: member) }

        it "leaves crops behind, reassigned to cropbot" do
          expect(Crop.all).to include(crop)
        end
      end

      context 'forum owners' do
        let!(:forum) { FactoryBot.create(:forum, owner: member) }

        it "leaves forums behind, reassigned to ex_admin" do
          expect(forum.owner).to eq(member)
        end
      end
    end
  end
end
