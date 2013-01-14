require 'spec_helper'

describe Garden do
  before :each do
    @owner  = FactoryGirl.create(:member)
    @garden = FactoryGirl.create(:garden, :owner => @owner)
  end

  it "should have a slug" do
    @garden.garden_slug.should == "member1-springfield-community-garden"
  end

  it "should have an owner" do
    @garden.owner.should be_an_instance_of Member
  end
end
