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

    it 'has a creator' do
      @crop.save
      @crop.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      @crop = FactoryGirl.build(:crop, :system_name => nil)
      expect { @crop.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context 'ordering' do
    before(:each) do
      @uppercase = FactoryGirl.create(:uppercasecrop, :created_at => 1.minute.ago)
      @lowercase = FactoryGirl.create(:lowercasecrop, :created_at => 2.days.ago)
    end

    it "should be sorted case-insensitively" do
      Crop.first.should == @lowercase
    end

    it 'recent scope sorts by creation date' do
      Crop.recent.first.should == @uppercase
    end
  end

  it 'finds a default scientific name' do
    @crop = FactoryGirl.create(:tomato)
    @crop.default_scientific_name.should eq nil
    @sn = FactoryGirl.create(:solanum_lycopersicum, :crop => @crop)
    @crop.default_scientific_name.should eq @sn.scientific_name
  end

  it 'counts plantings' do
    @crop = FactoryGirl.create(:tomato)
    @crop.plantings.size.should eq 0
    @planting = FactoryGirl.create(:planting, :crop => @crop)
    @crop.reload
    @crop.plantings.size.should eq 1
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

    it 'toplevel scope works' do
      @tomato = FactoryGirl.create(:tomato)
      @roma = FactoryGirl.create(:roma, :parent_id => @tomato.id)
      Crop.toplevel.should eq [ @tomato ]
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

  context 'sunniness' do
    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'returns a hash of sunniness values' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => @crop)
      planting4 = FactoryGirl.create(:shady_planting, :crop => @crop)
      @crop.sunniness.should be_an_instance_of Hash
    end

    it 'counts each sunniness value' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => @crop)
      planting4 = FactoryGirl.create(:shady_planting, :crop => @crop)
      @crop.sunniness.should == { 'sun' => 2, 'shade' => 1, 'semi-shade' => 1 }
    end

    it 'ignores unused sunniness values' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => @crop)
      @crop.sunniness.should == { 'sun' => 2, 'semi-shade' => 1 }
    end
  end

  context 'planted_from' do
    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'returns a hash of sunniness values' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => @crop)
      planting4 = FactoryGirl.create(:cutting_planting, :crop => @crop)
      @crop.planted_from.should be_an_instance_of Hash
    end

    it 'counts each planted_from value' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => @crop)
      planting4 = FactoryGirl.create(:cutting_planting, :crop => @crop)
      @crop.planted_from.should == { 'seed' => 2, 'seedling' => 1, 'cutting' => 1 }
    end

    it 'ignores unused planted_from values' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => @crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => @crop)
      @crop.planted_from.should == { 'seed' => 2, 'seedling' => 1 }
    end
  end

  context 'interesting' do
    it 'lists interesting crops' do
      # first, a couple of candidate crops
      @crop1 = FactoryGirl.create(:crop)
      @crop2 = FactoryGirl.create(:crop)

      # they need 3+ plantings each to be interesting
      (1..3).each do
        FactoryGirl.create(:planting, :crop => @crop1)
      end
      (1..3).each do
        FactoryGirl.create(:planting, :crop => @crop2)
      end

      # crops need 3+ photos to be interesting
      @photo = FactoryGirl.create(:photo)
      [@crop1, @crop2].each do |c|
        (1..3).each do
          c.plantings.first.photos << @photo
          c.plantings.first.save
        end
      end

      Crop.interesting.should include @crop1
      Crop.interesting.should include @crop2
      Crop.interesting.length.should == 2
    end

    it 'ignores crops without plantings' do
      # first, a couple of candidate crops
      @crop1 = FactoryGirl.create(:crop)
      @crop2 = FactoryGirl.create(:crop)

      # only crop1 has plantings
      (1..3).each do
        FactoryGirl.create(:planting, :crop => @crop1)
      end

      # ... and photos
      @photo = FactoryGirl.create(:photo)
      (1..3).each do
        @crop1.plantings.first.photos << @photo
        @crop1.plantings.first.save
      end

      Crop.interesting.should include @crop1
      Crop.interesting.should_not include @crop2
      Crop.interesting.length.should == 1

    end

    it 'ignores crops without photos' do
      # first, a couple of candidate crops
      @crop1 = FactoryGirl.create(:crop)
      @crop2 = FactoryGirl.create(:crop)

      # both crops have plantings
      (1..3).each do
        FactoryGirl.create(:planting, :crop => @crop1)
      end
      (1..3).each do
        FactoryGirl.create(:planting, :crop => @crop2)
      end

      # but only crop1 has photos
      @photo = FactoryGirl.create(:photo)
      (1..3).each do
        @crop1.plantings.first.photos << @photo
        @crop1.plantings.first.save
      end

      Crop.interesting.should include @crop1
      Crop.interesting.should_not include @crop2
      Crop.interesting.length.should == 1
    end

  end

end
