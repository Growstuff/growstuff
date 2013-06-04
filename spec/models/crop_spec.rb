require 'spec_helper'

describe Crop do
  context 'all fields present' do

    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'should save a basic crop' do
      @crop.save.should be_true
    end

    it 'should be fetchable from the database' do
      @crop.save
      @crop2 = Crop.find_by_system_name('Tomato')
      @crop2.en_wikipedia_url.should == "http://en.wikipedia.org/wiki/Tomato"
      @crop2.slug.should == "tomato"
    end

    it 'should stringify as the system name' do
      @crop.save
      @crop.to_s.should == 'Tomato'
      "#{@crop}".should == 'Tomato'
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      @crop = FactoryGirl.build(:crop, :system_name => nil)
      expect { @crop.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context 'ordering' do
    it "should be sorted case-insensitively" do
      uppercase = FactoryGirl.create(:uppercasecrop)
      lowercase = FactoryGirl.create(:lowercasecrop)
      Crop.first.should == lowercase
    end
  end

  it 'finds a default scientific name' do
    @c = FactoryGirl.create(:tomato)
    @c.default_scientific_name.should eq nil
    @sn = FactoryGirl.create(:solanum_lycopersicum, :crop => @c)
    @c.default_scientific_name.should eq @sn.scientific_name
  end

  it 'counts plantings' do
    @c = FactoryGirl.create(:tomato)
    @c.plantings_count.should eq 0
    FactoryGirl.create(:planting, :crop => @c)
    @c.plantings_count.should eq 1
  end

  it 'validates en_wikipedia_url' do
    @crop = FactoryGirl.build(:tomato, :en_wikipedia_url => 'this is not valid')
    @crop.should_not be_valid
    @crop = FactoryGirl.build(:tomato, :en_wikipedia_url => 'http://en.wikipedia.org/wiki/SomePage')
    @crop.should be_valid
  end

  context 'varieties' do
    it 'has a crop hierarchy' do
      @tomato = FactoryGirl.create(:tomato)
      @roma = FactoryGirl.create(:roma, :parent_id => @tomato.id)
      @roma.parent.should eq @tomato
      @tomato.varieties.should eq [@roma]
    end
  end

  context 'photos' do
    it 'has a default photo' do
      @crop = FactoryGirl.create(:tomato)
      @planting = FactoryGirl.create(:planting, :crop => @crop)
      @photo = FactoryGirl.create(:photo)
      @planting.photos << @photo
      @crop.default_photo.should be_an_instance_of Photo
    end
  end
end
