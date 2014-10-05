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
      @crop2 = Crop.find_by_name('tomato')
      @crop2.en_wikipedia_url.should == "http://en.wikipedia.org/wiki/Tomato"
      @crop2.slug.should == "tomato"
    end

    it 'should stringify as the system name' do
      @crop.save
      @crop.to_s.should == 'tomato'
      "#{@crop}".should == 'tomato'
    end

    it 'has a creator' do
      @crop.save
      @crop.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      @crop = FactoryGirl.build(:crop, :name => nil)
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

  context 'popularity' do
    before (:each) do
      @tomato = FactoryGirl.create(:tomato)
      @maize = FactoryGirl.create(:maize)
      @cucumber = FactoryGirl.create(:crop, :name => 'cucumber')
      FactoryGirl.create_list(:planting, 10, :crop => @maize)
      FactoryGirl.create_list(:planting, 3, :crop => @tomato)
    end

    it "sorts by most plantings" do
      Crop.popular.first.should eq @maize
      FactoryGirl.create_list(:planting, 10, :crop => @tomato)
      Crop.popular.first.should eq @tomato
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

  context 'popular plant parts' do
    before(:each) do
      @crop = FactoryGirl.create(:tomato)
    end

    it 'returns a hash of plant_part values' do
      @crop.popular_plant_parts.should be_an_instance_of Hash
    end

    it 'counts each plant_part value' do
      @fruit = FactoryGirl.create(:plant_part)
      @seed = FactoryGirl.create(:plant_part)
      @root = FactoryGirl.create(:plant_part)
      @bulb = FactoryGirl.create(:plant_part)
      @harvest1 = FactoryGirl.create(:harvest,
        :crop => @crop,
        :plant_part => @fruit
      )
      @harvest2 = FactoryGirl.create(:harvest,
        :crop => @crop,
        :plant_part => @fruit
      )
      @harvest3 = FactoryGirl.create(:harvest,
        :crop => @crop,
        :plant_part => @seed
      )
      @harvest4 = FactoryGirl.create(:harvest,
        :crop => @crop,
        :plant_part => @root
      )
      @crop.popular_plant_parts.should == { @fruit => 2, @seed => 1, @root => 1 }
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

  context "harvests" do
    it "has harvests" do
      crop = FactoryGirl.create(:crop)
      harvest = FactoryGirl.create(:harvest, :crop => crop)
      crop.harvests.should eq [harvest]
    end
  end

  it 'has plant_parts' do
    @maize = FactoryGirl.create(:maize)
    @pp1 = FactoryGirl.create(:plant_part)
    @pp2 = FactoryGirl.create(:plant_part)
    @h1 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @h2 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp2
    )
    @maize.plant_parts.should include @pp1
    @maize.plant_parts.should include @pp2
  end

  it "doesn't dupliate plant_parts" do
    @maize = FactoryGirl.create(:maize)
    @pp1 = FactoryGirl.create(:plant_part)
    @h1 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @h2 = FactoryGirl.create(:harvest,
      :crop => @maize,
      :plant_part => @pp1
    )
    @maize.plant_parts.should eq [@pp1]
  end

  context "search" do
    before :each do
      @mushroom = FactoryGirl.create(:crop, :name => 'mushroom')
    end
    it "finds exact matches" do
      Crop.search('mushroom').should eq [@mushroom]
    end
    it "finds approximate matches" do
      Crop.search('mush').should eq [@mushroom]
    end
    it "doesn't find non-matches" do
      Crop.search('mush').should_not include @crop
    end
    it "searches case insensitively" do
      Crop.search('mUsH').should include @mushroom
    end
  end

  context "crop-post association" do
    let!(:tomato) { FactoryGirl.create(:tomato) }
    let!(:maize) { FactoryGirl.create(:maize) }
    let!(:post) { FactoryGirl.create(:post, :body => "[maize](crop)[tomato](crop)[tomato](crop)") }

    describe "destroying a crop" do
      before do
        tomato.destroy
      end

      it "should delete the association between post and the crop(tomato)" do
        expect(Post.find(post).crops).to eq [maize]
      end

      it "should not delete the posts" do
        expect(Post.find(post)).to_not eq nil
      end
    end
  end
end
