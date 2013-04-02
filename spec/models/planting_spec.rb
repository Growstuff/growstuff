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

  it "sorts plantings in descending order of creation" do
    @planting1 = FactoryGirl.create(:planting)
    @planting2 = FactoryGirl.create(:planting)
    Planting.first.should eq @planting2
  end

  it "should have a slug" do
    @planting.slug.should match /^member\d+-springfield-community-garden-tomato$/
  end

  it "should accept ISO-format dates" do
    @planting.planted_at_string = "2013-03-01"
    @planting.planted_at.should == Time.local(2013, 03, 01)
  end

  it "should accept DD Month YY format dates" do
    @planting.planted_at_string = "1st March 13" # Dydd Gŵyl Dewi Hapus!
    @planting.planted_at.should == Time.local(2013, 03, 01)
  end

  it 'should accept blank dates' do
    @planting.planted_at_string = ''
    @planting.planted_at.should == nil
  end

  it "should output dates in ISO format" do
    @planting.planted_at = Time.local(2013, 03, 01)
    @planting.planted_at_string.should == "2013-03-01"
  end

  it 'should have a sunniness value' do
    @planting.sunniness.should eq 'sun'
  end

  it 'all three valid sunniness values should work' do
    ['sun', 'shade', 'semi-shade', nil, ''].each do |s|
      @planting = FactoryGirl.build(:planting, :sunniness => s)
      @planting.should be_valid
    end
  end

  it 'should refuse invalid sunniness values' do
    @planting = FactoryGirl.build(:planting, :sunniness => 'not valid')
    @planting.should_not be_valid
    @planting.errors[:sunniness].should include("not valid is not a valid sunniness value")
  end

end
