require 'spec_helper'

describe 'user' do

  context 'valid user' do
    before(:each) do
      @user = User.new
      @user.email = "example@example.com"
      @user.username = "someone"
      @user.password = "irrelevant"
      @user.tos_agreement = true
    end

    it 'should save a basic user' do
      @user.save.should be_true
    end

    it 'should be fetchable from the database' do
      @user.save
      @user2 = User.find_by_email('example@example.com')
      @user2.email.should == "example@example.com"
      @user2.username.should == "someone"
      @user2.slug.should == "someone"
      @user2.encrypted_password.should_not be_nil
    end

    it 'should have a default garden' do
      @user.save
      @user.gardens.count.should == 1
    end
  end

  context 'no TOS agreement' do
    before(:each) do
      @user = User.new
      @user.email = "example@example.com"
      @user.username = "someone"
      @user.password = "irrelevant"
    end

    it "should refuse to save a user who hasn't agreed to the TOS" do
      @user.save.should_not be_true
    end
  end

end
