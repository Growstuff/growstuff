require 'spec_helper'

describe 'test users' do
  it 'should have 3 test users' do
    (1..3).each do |i|
      @user = User.find_by_username("test#{i}")
      @user.email.should == "test#{i}@example.com"
    end
  end
end
