require 'spec_helper'

describe 'user' do

  before(:each) do
    @user = User.new
    @user.email = "example@example.com"
    @user.username = "someone"
    @user.password = "irrelevant"
  end

  it 'should save a basic user' do
    @user.save.should be_true
  end

  it 'should be fetchable from the database' do
    @user.save
    @user2 = User.find_by_email('example@example.com')
    @user2.email.should == "example@example.com"
    @user2.username.should == "someone"
    @user2.encrypted_password.should_not be_nil
  end

end
