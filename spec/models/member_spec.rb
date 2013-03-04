require 'spec_helper'

describe 'member' do

  context 'valid member' do
    before(:each) do
      @member = FactoryGirl.build(:member)
    end

    it 'should save a basic member' do
      @member.save.should be_true
    end

    it 'should be fetchable from the database' do
      @member.save
      @member2 = Member.find(@member.id)
      @member2.should be_an_instance_of Member
      @member2.login_name.should match(/member\d+/)
      @member2.encrypted_password.should_not be_nil
    end

    it 'should have a friendly slug' do
      @member.save
      @member.slug.should match(/member\d+/)
    end

    it 'should have a default garden' do
      @member.save
      @member.gardens.count.should == 1
    end

    it "doesn't show email by default" do
      @member.save
      @member.show_email.should be_false
    end

    it 'should stringify as the login_name' do
      @member.save
      @member.to_s.should match(/member\d+/)
      "#{@member}".should match(/member\d+/)
    end

    it 'should be able to fetch posts' do
      @post = FactoryGirl.create(:post, :author => @member)
      @member.posts.should eq [@post]
    end

    it 'should be able to fetch gardens' do
      @member.save
      @member.gardens.first.name.should eq "Garden"
    end

    it 'has many plantings through gardens' do
      @member.save
      @planting = FactoryGirl.create(:planting,
        :garden => @member.gardens.first
      )
      @member.plantings.count.should eq 1
    end

    it "has many comments" do
      @member.save
      @comment1 = FactoryGirl.create(:comment, :author => @member)
      @comment2 = FactoryGirl.create(:comment, :author => @member)
      @member.comments.length.should == 2
    end

    it "has many forums" do
      @member.save
      @forum1 = FactoryGirl.create(:forum, :owner => @member)
      @forum2 = FactoryGirl.create(:forum, :owner => @member)
      @member.forums.length.should == 2
    end

    it 'has location and lat/long fields' do
      @member.update_attributes(:location => 'Greenwich, UK')
      @member.location.should eq 'Greenwich, UK'
      @member.latitude.round(2).should eq 51.48
      @member.longitude.round(2).should eq 0.00
    end

    it 'empties the lat/long if location removed' do
      @member.update_attributes(:location => 'Greenwich, UK')
      @member.update_attributes(:location => '')
      @member.location.should eq ''
      @member.latitude.should be_nil
      @member.longitude.should be_nil
    end

    it "has a full name" do
      @member.full_name.should eq "Fake McNamerson"
    end

    it 'has an "about me" section' do
      @member.about_me.should eq "I like to garden all day long"
    end

    it 'has a gardening_since field' do
      @member.gardening_since.should eq "Last February"
    end

    it 'has a wish_i_could_grow field' do
      @member.wish_i_could_grow.should eq "turnips"
    end

    it 'has a gardening_clothes field' do
      @member.gardening_clothes.should eq "a jolly hat"
    end

  end

  context 'no TOS agreement' do
    before(:each) do
      @member = FactoryGirl.build(:no_tos_member)
    end

    it "should refuse to save a member who hasn't agreed to the TOS" do
      @member.save.should_not be_true
    end
  end

  context 'same :login_name' do
    it "should not allow two members with the same login_name" do
      FactoryGirl.create(:member, :login_name => "bob")
      member = FactoryGirl.build(:member, :login_name => "bob")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end

    it "tests uniqueness case-insensitively" do
      FactoryGirl.create(:member, :login_name => "bob")
      member = FactoryGirl.build(:member, :login_name => "BoB")
      member.should_not be_valid
      member.errors[:login_name].should include("has already been taken")
    end
  end

  context 'case sensitivity' do
    it 'preserves case of login name' do
      member = FactoryGirl.create(:member, :login_name => "BOB")
      check = Member.find('bob')
      check.login_name.should eq 'BOB'
    end
  end

  context 'ordering' do
    it "should be sorted by name" do
      z = FactoryGirl.create(:member, :login_name => "Zoe")
      a = FactoryGirl.create(:member, :login_name => "Anna")
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
    before(:each) do
      @member = FactoryGirl.create(:member)
      @role = FactoryGirl.create(:role)
      @member.roles << @role
    end

    it 'has a role' do
      @member.roles.first.should eq @role
      @member.has_role?(:moderator).should eq true
    end

    it 'sets up roles in factories' do
      @admin = FactoryGirl.create(:admin_member)
      @admin.has_role?(:admin).should eq true
    end

    it 'converts role names properly' do
      # need to make sure spaces get turned to underscores
      @role = FactoryGirl.create(:role, :name => "a b c")
      @member.roles << @role
      @member.has_role?(:a_b_c).should eq true
    end
  end

end
