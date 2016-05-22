require 'rails_helper'

describe 'member' do

  context 'valid member' do

    let(:member) { FactoryGirl.create(:member) }

    it 'should be fetchable from the database' do
      @member2 = Member.find(member.id)
      @member2.should be_an_instance_of Member
      @member2.login_name.should match(/member\d+/)
      @member2.encrypted_password.should_not be_nil
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

    it 'should have a accounts entry' do
      member.account.should be_an_instance_of Account
    end

    it "should have a default-type account by default" do
      member.account.account_type.name.should eq Growstuff::Application.config.default_account_type
      member.is_paid?.should be(false)
    end

    it "doesn't show email by default" do
      member.show_email.should be(false)
    end

    it 'should stringify as the login_name' do
      member.to_s.should match(/member\d+/)
      "#{member}".should match(/member\d+/)
    end

    it 'should be able to fetch posts' do
      @post = FactoryGirl.create(:post, author: member)
      member.posts.should eq [@post]
    end

    it 'should be able to fetch gardens' do
      member.gardens.first.name.should eq "Garden"
    end

    it 'has many plantings' do
      @planting = FactoryGirl.create(:planting, owner: member)
      member.plantings.size.should eq 1
    end

    it "has many comments" do
      @comment1 = FactoryGirl.create(:comment, author: member)
      @comment2 = FactoryGirl.create(:comment, author: member)
      member.comments.size.should == 2
    end

    it "has many forums" do
      @forum1 = FactoryGirl.create(:forum, owner: member)
      @forum2 = FactoryGirl.create(:forum, owner: member)
      member.forums.size.should == 2
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

    let(:member) { FactoryGirl.build(:no_tos_member) }

    it "should refuse to save a member who hasn't agreed to the TOS" do
      member.save.should_not be(true)
    end
  end

  context 'newsletter scope' do
    it 'finds newsletter recipients' do
      @member1 = FactoryGirl.create(:member)
      @member2 = FactoryGirl.create(:newsletter_recipient_member)
      Member.wants_newsletter.should include @member2
      Member.wants_newsletter.should_not include @member1
    end
  end

  context 'same :login_name' do
    it "should not allow two members with the same login_name" do
      FactoryGirl.create(:member, login_name: "bob")
      member = FactoryGirl.build(:member, login_name: "bob")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end

    it "tests uniqueness case-insensitively" do
      FactoryGirl.create(:member, login_name: "bob")
      member = FactoryGirl.build(:member, login_name: "BoB")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end
  end

  context 'case sensitivity' do
    it 'preserves case of login name' do
      member = FactoryGirl.create(:member, login_name: "BOB")
      check = Member.find('bob')
      check.login_name.should eq 'BOB'
    end
  end

  context 'ordering' do
    it "should be sorted by name" do
      z = FactoryGirl.create(:member, login_name: "Zoe")
      a = FactoryGirl.create(:member, login_name: "Anna")
      Member.first.should == a
    end
  end

  context 'invalid login names' do
    it "doesn't allow short names" do
      member = FactoryGirl.build(:invalid_member_shortname)
      member.should_not be_valid
      member.errors[:login_name].should include("should be between 2 and 25 characters long")
    end
    it "doesn't allow really long names" do
      member = FactoryGirl.build(:invalid_member_longname)
      member.should_not be_valid
      member.errors[:login_name].should include("should be between 2 and 25 characters long")
    end
    it "doesn't allow spaces in names" do
      member = FactoryGirl.build(:invalid_member_spaces)
      member.should_not be_valid
      member.errors[:login_name].should include("may only include letters, numbers, or underscores")
    end
    it "doesn't allow other chars in names" do
      member = FactoryGirl.build(:invalid_member_badchars)
      member.should_not be_valid
      member.errors[:login_name].should include("may only include letters, numbers, or underscores")
    end
    it "doesn't allow reserved names" do
      member = FactoryGirl.build(:invalid_member_badname)
      member.should_not be_valid
      member.errors[:login_name].should include("name is reserved")
    end
  end

  context 'valid login names' do
    it "allows plain alphanumeric chars in names" do
      member = FactoryGirl.build(:valid_member_alphanumeric)
      member.should be_valid
    end
    it "allows uppercase chars in names" do
      member = FactoryGirl.build(:valid_member_uppercase)
      member.should be_valid
    end
    it "allows underscores in names" do
      member = FactoryGirl.build(:valid_member_underscore)
      member.should be_valid
    end
  end

  context 'roles' do

    let(:member) { FactoryGirl.create(:member) }
    let(:role) { FactoryGirl.create(:role) }

    before do
      member.roles << role
    end

    it 'has a role' do
      member.roles.first.should eq role
      member.has_role?(:moderator).should eq true
    end

    it 'sets up roles in factories' do
      @admin = FactoryGirl.create(:admin_member)
      @admin.has_role?(:admin).should eq true
    end

    it 'converts role names properly' do
      # need to make sure spaces get turned to underscores
      @role = FactoryGirl.create(:role, name: "a b c")
      member.roles << @role
      member.has_role?(:a_b_c).should eq true
    end
  end

  context 'confirmed scope' do
    before(:each) do
      @member1 = FactoryGirl.create(:member)
      @member2 = FactoryGirl.create(:member)
    end

    it 'sees confirmed members' do
      Member.confirmed.size.should == 2
    end

    it 'ignores unconfirmed members' do
      @member3 = FactoryGirl.create(:unconfirmed_member)
      Member.confirmed.size.should == 2
    end
  end

  context 'located scope' do
    # located members must have location, lat, long
    it 'finds members who have locations' do
      @london_member = FactoryGirl.create(:london_member)
      Member.located.should include @london_member
    end

    it 'ignores members with blank locations' do
      @nowhere_member = FactoryGirl.create(:member)
      Member.located.should_not include @nowhere_member
    end

    it 'ignores members with blank lat/long' do
      @london_member = FactoryGirl.create(:london_member)
      @london_member.latitude = nil
      @london_member.longitude = nil
      @london_member.save(validate: false)
      Member.located.should_not include @london_member
    end
  end

  context 'near location' do
    it 'finds nearby members and sorts them' do
      @edinburgh_member = FactoryGirl.create(:edinburgh_member)
      @london_member = FactoryGirl.create(:london_member)
      Member.nearest_to('Greenwich, UK').should eq [@london_member, @edinburgh_member]
    end
  end

  context 'interesting scope' do
    # interesting members are defined as:
    # 1) confirmed
    # 2) have a location
    # 3) have at least one planting
    # 4) ordered by the most recent sign in

    it 'finds interesting members' do
      @member1 = FactoryGirl.create(:london_member)
      @member2 = FactoryGirl.create(:london_member)
      @member3 = FactoryGirl.create(:london_member)
      @member4 = FactoryGirl.create(:unconfirmed_member)

      [@member1, @member2, @member3, @member4].each do |m|
        FactoryGirl.create(:planting, owner: m)
      end

      @member1.updated_at = 3.days.ago
      @member2.updated_at = 2.days.ago
      @member3.updated_at = 1.days.ago

      Member.interesting.should eq [ @member3, @member2, @member1 ]

    end

  end

  context 'orders' do
    it 'finds the current order' do
      @member = FactoryGirl.create(:member)
      @order1 = FactoryGirl.create(:completed_order, member: @member)
      @order2 = FactoryGirl.create(:order, member: @member)
      @member.current_order.should eq @order2
    end

    it "copes if there's no current order" do
      @member = FactoryGirl.create(:member)
      @order1 = FactoryGirl.create(:completed_order, member: @member)
      @order2 = FactoryGirl.create(:completed_order, member: @member)
      @member.current_order.should be_nil
    end
  end

  context "paid accounts" do

    let(:member) { FactoryGirl.create(:member) }

    it "recognises a permanent paid account" do
      @account_type = FactoryGirl.create(:account_type,
          is_paid: true, is_permanent_paid: true)
      member.account.account_type = @account_type
      member.is_paid?.should be(true)
    end

    it "recognises a current paid account" do
      @account_type = FactoryGirl.create(:account_type,
          is_paid: true, is_permanent_paid: false)
      member.account.account_type = @account_type
      member.account.paid_until = Time.zone.now + 1.month
      member.is_paid?.should be(true)
    end

    it "recognises an expired paid account" do
      @account_type = FactoryGirl.create(:account_type,
          is_paid: true, is_permanent_paid: false)
      member.account.account_type = @account_type
      member.account.paid_until = Time.zone.now - 1.minute
      member.is_paid?.should be(false)
    end

    it "recognises a free account" do
      @account_type = FactoryGirl.create(:account_type,
          is_paid: false, is_permanent_paid: false)
      member.account.account_type = @account_type
      member.is_paid?.should be(false)
    end

    it "recognises a free account even with paid_until set" do
      @account_type = FactoryGirl.create(:account_type,
          is_paid: false, is_permanent_paid: false)
      member.account.account_type = @account_type
      member.account.paid_until = Time.zone.now + 1.month
      member.is_paid?.should be(false)
    end

  end

  context "update account" do

    let(:product) { FactoryGirl.create(:product,
      paid_months: 3
    )}
    let(:member) { FactoryGirl.create(:member) }

    it "sets account_type" do
      member.update_account_after_purchase(product)
      member.account.account_type.should eq product.account_type
    end

    it "sets paid_until" do
      member.account.paid_until = nil # blank for now, as if never paid before
      member.update_account_after_purchase(product)

      # stringify to avoid millisecond problems...
      member.account.paid_until.to_s.should eq (Time.zone.now + 3.months).to_s

      # and again to make sure it works for currently paid accounts
      member.update_account_after_purchase(product)
      member.account.paid_until.to_s.should eq (Time.zone.now + 3.months + 3.months).to_s
    end
  end

  context 'harvests' do
    it 'has harvests' do
      member = FactoryGirl.create(:member)
      harvest = FactoryGirl.create(:harvest, owner: member)
      member.harvests.should eq [harvest]
    end
  end

  context 'member who followed another member' do
    

    let(:member1) { FactoryGirl.create(:member) }
    let(:member2) { FactoryGirl.create(:member) }
    let(:member3) { FactoryGirl.create(:member) }    

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

end
