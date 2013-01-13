require 'spec_helper'

describe 'member' do

  context 'valid member' do
    before(:each) do
      @member = FactoryGirl.create(:member)
    end

    it 'should save a basic member' do
      @member.save.should be_true
    end

    it 'should be fetchable from the database' do
      @member.save
      @member2 = Member.find_by_email('member1@example.com')
      @member2.login_name.should == "member1"
      @member2.email.should    == "member1@example.com"
      @member2.slug.should     == "member1"
      @member2.encrypted_password.should_not be_nil
    end

    it 'should have a default garden' do
      @member.save
      @member.gardens.count.should == 1
    end

    it 'should stringify as the login_name' do
      @member.to_s.should == 'member1'
      "#{@member}".should == 'member1'
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

end
