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

  context 'sunniness' do
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

  context 'planted from' do
    it 'should have a planted_from value' do
      @planting.planted_from.should eq 'seed'
    end

    it 'all valid planted_from values should work' do
      ['seed', 'seedling', 'cutting', 'root division',
        'runner', 'bare root plant', 'advanced plant',
        'graft', 'layering', nil, ''].each do |p|
        @planting = FactoryGirl.build(:planting, :planted_from => p)
        @planting.should be_valid
      end
    end

    it 'should refuse invalid planted_from values' do
      @planting = FactoryGirl.build(:planting, :planted_from => 'not valid')
      @planting.should_not be_valid
      @planting.errors[:planted_from].should include("not valid is not a valid planting method")
    end
  end

  # we decided that all the tests for the planting/photo association would
  # be done on this side, not on the photos side
  context 'photos' do
    before(:each) do
      @planting = FactoryGirl.create(:planting)
      @photo = FactoryGirl.create(:photo)
      @planting.photos << @photo
    end

    it 'has a photo' do
      @planting.photos.first.should eq @photo
    end

    it 'deletes association with photos when photo is deleted' do
      @photo.destroy
      @planting.reload
      @planting.photos.should be_empty
    end

    it 'has a default photo' do
      @planting.default_photo.should eq @photo
    end

    it 'chooses the most recent photo' do
      @photo2 = FactoryGirl.create(:photo)
      @planting.photos << @photo2
      @planting.default_photo.should eq @photo2
    end
  end

end
