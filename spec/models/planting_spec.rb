require 'spec_helper'

describe Planting do

  before(:each) do
    @crop     = FactoryGirl.create(:tomato)
    @member     = FactoryGirl.create(:member)
    @garden   = FactoryGirl.create(:garden, :member => @member)
    @planting = FactoryGirl.create(:planting,
        :crop => @crop, :garden => @garden)
  end

  it "generates an owner" do
    @planting.owner.should be_an_instance_of Member
    @planting.owner.username.should match /^member1$/
  end

  it "generates a location" do
    @planting.location.should match /^member1's My Garden$/
  end

end
