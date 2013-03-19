require 'spec_helper'

describe 'new gardens' do
  it "should have 'my garden' for each user" do
    (1..3).each do |i|
      @user = User.find_by_username("test#{i}")
      @garden = Garden.find(:name => "My Garden", :user_id => @user.id)
      @garden.should_exist
      @garden.slug.should == "test#{i}-my-garden"
    end
  end
end
