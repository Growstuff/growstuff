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
    @planting.owner.login_name.should match /^member\d+$/
  end

  it "generates a location" do
    @planting.location.should match /^member\d+'s Springfield Community Garden$/
  end

  it "should have a slug" do
    @planting.slug.should match /^member\d+-springfield-community-garden-tomato$/
  end

end
