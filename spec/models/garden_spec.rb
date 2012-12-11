require 'spec_helper'

describe Garden do
  it "should have a slug" do
    user = mock_model(User)
    user.stub!(:username).and_return("test1")
    garden = Garden.new(:name => "my garden")
    garden.user = user
    garden.garden_slug.should == "test1-my garden"
  end
end
