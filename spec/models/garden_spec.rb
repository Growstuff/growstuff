require 'spec_helper'

describe Garden do
  before :each do
    @user   = FactoryGirl.create(:user)
    @garden = FactoryGirl.create(:garden, :user => @user)
  end

  it "should have a slug" do
    @garden.garden_slug.should == "user1-my-garden"
  end

  it "should have an owner" do
    @garden.owner.should be_an_instance_of User
  end
end
