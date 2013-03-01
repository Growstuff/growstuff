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

  it "should accept ISO-format dates" do
    @planting.planted_at_string = "2013-03-01"
    @planting.planted_at.should == Date.new(2013, 03, 01)
  end

  it "should accept DD Month YY format dates" do
    @planting.planted_at_string = "1st March 13" # Dydd Gŵyl Dewi Hapus!
    @planting.planted_at.should == Date.new(2013, 03, 01)
  end

  it "should output dates in ISO format" do
    @planting.planted_at = Date.new(2013, 03, 01)
    @planting.planted_at_string.should == "2013-03-01"
  end

end
