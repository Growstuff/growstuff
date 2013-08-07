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

  context 'quantity' do
    it 'allows integer quantities' do
      @planting = FactoryGirl.build(:planting, :quantity => 99)
      @planting.should be_valid
    end

    it "doesn't allow decimal quantities" do
      @planting = FactoryGirl.build(:planting, :quantity => 99.9)
      @planting.should_not be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @planting = FactoryGirl.build(:planting, :quantity => 'foo')
      @planting.should_not be_valid
    end

    it "allows blank quantities" do
      @planting = FactoryGirl.build(:planting, :quantity => nil)
      @planting.should be_valid
      @planting = FactoryGirl.build(:planting, :quantity => '')
      @planting.should be_valid
    end
  end

  context 'sunniness' do
    before(:each) do
      @planting = FactoryGirl.create(:sunny_planting)
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

  context 'planted from' do
    it 'should have a planted_from value' do
      @planting = FactoryGirl.create(:seed_planting)
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

  context 'interesting crops' do
    it 'picks up interesting plantings' do
      # plantings have members created implicitly for them
      # each member is different, hence these are all interesting
      @planting1 = FactoryGirl.create(:planting, :created_at => 5.days.ago)
      @planting2 = FactoryGirl.create(:planting, :created_at => 4.days.ago)
      @planting3 = FactoryGirl.create(:planting, :created_at => 3.days.ago)
      @planting4 = FactoryGirl.create(:planting, :created_at => 2.days.ago)

      # plantings need photos to be interesting
      @photo = FactoryGirl.create(:photo)
      [@planting1, @planting2, @planting3, @planting4].each do |p|
        p.photos << @photo
        p.save
      end

      Planting.interesting.should eq [
        @planting4,
        @planting3,
        @planting2,
        @planting1
      ]
    end

    it 'ignores plantings without photos' do
      # first, an interesting planting
      @planting = FactoryGirl.create(:planting)
      @planting.photos << FactoryGirl.create(:photo)
      @planting.save

      # this one doesn't have a photo
      @boring_planting = FactoryGirl.create(:planting)

      Planting.interesting.should include @planting
      Planting.interesting.should_not include @boring_planting
    end

    it 'ignores plantings with the same owner' do
      # this planting is older
      @planting1 = FactoryGirl.create(:planting, :created_at => 1.day.ago)
      @planting1.photos << FactoryGirl.create(:photo)
      @planting1.save

      # this one is newer, and has the same owner, through the garden
      @planting2 = FactoryGirl.create(:planting,
        :created_at => 1.minute.ago,
        :garden_id => @planting1.garden.id
      )
      @planting2.photos << FactoryGirl.create(:photo)
      @planting2.save

      # result: the newer one is interesting, the older one isn't
      Planting.interesting.should include @planting2
      Planting.interesting.should_not include @planting1
    end

    it 'only gives you as many as you ask for' do
      # plantings have members created implicitly for them
      # each member is different, hence these are all interesting
      @planting1 = FactoryGirl.create(:planting, :created_at => 5.days.ago)
      @planting2 = FactoryGirl.create(:planting, :created_at => 4.days.ago)
      @planting3 = FactoryGirl.create(:planting, :created_at => 3.days.ago)
      @planting4 = FactoryGirl.create(:planting, :created_at => 2.days.ago)

      # plantings need photos to be interesting
      @photo = FactoryGirl.create(:photo)
      [@planting1, @planting2, @planting3, @planting4].each do |p|
        p.photos << @photo
        p.save
      end

      Planting.interesting(2).length.should == 2
    end

  end

end
