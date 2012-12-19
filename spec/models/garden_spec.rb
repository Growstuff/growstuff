require 'spec_helper'

describe Garden do
  before :each do
    @user = mock_model(User)
    @user.stub!(:username).and_return("test1")
    @garden = Garden.new(:name => "my garden")
    @garden.user = @user
  end

  it "should have a slug" do
    @garden.garden_slug.should == "test1-my garden"
  end

  it "should have an owner" do
    @garden.owner.should be_an_instance_of User
  end
end
