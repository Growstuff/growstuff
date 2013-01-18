require 'spec_helper'

describe Planting do

  before(:each) do
    @crop     = FactoryGirl.create(:tomato)
    @member   = FactoryGirl.create(:member)
    @garden   = FactoryGirl.create(:garden, :owner => @member)
    @planting = FactoryGirl.create(:planting,
        :crop => @crop, :garden => @garden)
  end

  it "generates an owner" do
    @planting.owner.should be_an_instance_of Member
    @planting.owner.login_name.should match /^member1$/
  end

  it "generates a location" do
    @planting.location.should match /^member1's Springfield Community Garden$/
  end

  it "should have a slug" do
    @planting.slug.should == "member1-springfield-community-garden-tomato"
  end

end
