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
    @planting.planted_at.should == Time.local(2013, 03, 01)
  end

  it "should accept DD Month YY format dates" do
    @planting.planted_at_string = "1st March 13" # Dydd Gŵyl Dewi Hapus!
    @planting.planted_at.should == Time.local(2013, 03, 01)
  end

  it "should output dates in ISO format" do
    @planting.planted_at = Time.local(2013, 03, 01)
    @planting.planted_at_string.should == "2013-03-01"
  end

  it 'should sort in reverse creation order' do
    @planting2 = FactoryGirl.create(:planting)
    Planting.first.should eq @planting2
  end

  context 'delegation' do
    it 'system name' do
      @planting.crop_system_name.should eq @planting.crop.system_name
    end
    it 'wikipedia url' do
      @planting.crop_en_wikipedia_url.should eq @planting.crop.en_wikipedia_url
    end
    it 'default scientific name' do
      @planting.crop_default_scientific_name.should eq @planting.crop.default_scientific_name
    end
    it 'plantings count' do
      @planting.crop_plantings_count.should eq @planting.crop.plantings_count
    end
  end

end
