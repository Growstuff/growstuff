require 'spec_helper'

describe 'user' do

  context 'valid user' do
    before(:each) do
      @user = FactoryGirl.create(:confirmed_user)
    end

    it 'should save a basic user' do
      @user.save.should be_true
    end

    it 'should be fetchable from the database' do
      @user.save
      @user2 = User.find_by_email('user1@example.com')
      @user2.username.should == "user1"
      @user2.email.should    == "user1@example.com"
      @user2.slug.should     == "user1"
      @user2.encrypted_password.should_not be_nil
    end

    it 'should have a default garden' do
      @user.save
      @user.gardens.count.should == 1
    end

    it 'should stringify as the username' do
      @user.to_s.should == 'user1'
      "#{@user}".should == 'user1'
    end
  end

  context 'no TOS agreement' do
    before(:each) do
      @user = FactoryGirl.build(:no_tos_user)
    end

    it "should refuse to save a user who hasn't agreed to the TOS" do
      @user.save.should_not be_true
    end
  end

end
