require 'rails_helper'

describe Crop do
  context 'all fields present' do

    let(:crop) { FactoryGirl.create(:tomato) }

    it 'should save a basic crop' do
      crop.save.should be(true)
    end

    it 'should be fetchable from the database' do
      crop.save
      @crop2 = Crop.find_by_name('tomato')
      @crop2.en_wikipedia_url.should == "http://en.wikipedia.org/wiki/Tomato"
      @crop2.slug.should == "tomato"
    end

    it 'should stringify as the system name' do
      crop.save
      crop.to_s.should == 'tomato'
      "#{crop}".should == 'tomato'
    end

    it 'has a creator' do
      crop.save
      crop.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      crop = FactoryGirl.build(:crop, :name => nil)
      expect { crop.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context 'ordering' do
    before do
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

    let(:tomato) { FactoryGirl.create(:tomato) }
    let(:maize) { FactoryGirl.create(:maize) }
    let(:cucumber) { FactoryGirl.create(:crop, :name => 'cucumber') }

    before do
      FactoryGirl.create_list(:planting, 10, :crop => maize)
      FactoryGirl.create_list(:planting, 3, :crop => tomato)
    end

    it "sorts by most plantings" do
      Crop.popular.first.should eq maize
      FactoryGirl.create_list(:planting, 10, :crop => tomato)
      Crop.popular.first.should eq tomato
    end

  end

  it 'finds a default scientific name' do
    @crop = FactoryGirl.create(:tomato)
    @crop.default_scientific_name.should eq nil
    @sn = FactoryGirl.create(:solanum_lycopersicum, :crop => @crop)
    @crop.reload
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

    let(:crop) { FactoryGirl.create(:tomato) }

    it 'returns a hash of sunniness values' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => crop)
      planting4 = FactoryGirl.create(:shady_planting, :crop => crop)
      crop.sunniness.should be_an_instance_of Hash
    end

    it 'counts each sunniness value' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => crop)
      planting4 = FactoryGirl.create(:shady_planting, :crop => crop)
      crop.sunniness.should == { 'sun' => 2, 'shade' => 1, 'semi-shade' => 1 }
    end

    it 'ignores unused sunniness values' do
      planting1 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting2 = FactoryGirl.create(:sunny_planting, :crop => crop)
      planting3 = FactoryGirl.create(:semi_shady_planting, :crop => crop)
      crop.sunniness.should == { 'sun' => 2, 'semi-shade' => 1 }
    end
  end

  context 'planted_from' do

    let(:crop) { FactoryGirl.create(:tomato) }

    it 'returns a hash of sunniness values' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => crop)
      planting4 = FactoryGirl.create(:cutting_planting, :crop => crop)
      crop.planted_from.should be_an_instance_of Hash
    end

    it 'counts each planted_from value' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => crop)
      planting4 = FactoryGirl.create(:cutting_planting, :crop => crop)
      crop.planted_from.should == { 'seed' => 2, 'seedling' => 1, 'cutting' => 1 }
    end

    it 'ignores unused planted_from values' do
      planting1 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting2 = FactoryGirl.create(:seed_planting, :crop => crop)
      planting3 = FactoryGirl.create(:seedling_planting, :crop => crop)
      crop.planted_from.should == { 'seed' => 2, 'seedling' => 1 }
    end
  end

  context 'popular plant parts' do

    let(:crop) { FactoryGirl.create(:tomato) }

    it 'returns a hash of plant_part values' do
      crop.popular_plant_parts.should be_an_instance_of Hash
    end

    it 'counts each plant_part value' do
      @fruit = FactoryGirl.create(:plant_part)
      @seed = FactoryGirl.create(:plant_part)
      @root = FactoryGirl.create(:plant_part)
      @bulb = FactoryGirl.create(:plant_part)
      @harvest1 = FactoryGirl.create(:harvest,
        :crop => crop,
        :plant_part => @fruit
      )
      @harvest2 = FactoryGirl.create(:harvest,
        :crop => crop,
        :plant_part => @fruit
      )
      @harvest3 = FactoryGirl.create(:harvest,
        :crop => crop,
        :plant_part => @seed
      )
      @harvest4 = FactoryGirl.create(:harvest,
        :crop => crop,
        :plant_part => @root
      )
      crop.popular_plant_parts.should == { @fruit => 2, @seed => 1, @root => 1 }
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
      Crop.interesting.size.should == 2
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
      Crop.interesting.size.should == 1

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
      Crop.interesting.size.should == 1
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

  it "doesn't duplicate plant_parts" do
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
    
    let(:mushroom) { FactoryGirl.create(:crop, :name => 'mushroom') }

    before do
      sync_elasticsearch([mushroom])
    end

    it "finds exact matches" do
      Crop.search('mushroom').should eq [mushroom]
    end
    it "finds approximate matches" do
      Crop.search('mush').should eq [mushroom]
    end
    it "doesn't find non-matches" do
      Crop.search('mush').should_not include @crop
    end
    it "searches case insensitively" do
      Crop.search('mUsH').should include mushroom
    end
    it "doesn't find 'rejected' crop" do
      @rejected_crop = FactoryGirl.create(:rejected_crop, :name => 'tomato')
      sync_elasticsearch([@rejected_crop])
      Crop.search('tomato').should_not include @rejected_crop
    end
    it "doesn't find 'pending' crop" do
      @crop_request = FactoryGirl.create(:crop_request, :name => 'tomato')
      sync_elasticsearch([@crop_request])
      Crop.search('tomato').should_not include @crop_request
    end
  end

  context "csv loading" do

    before(:each) do
      # don't use 'let' for this -- we need to actually create it,
      # regardless of whether it's used.
      @cropbot = FactoryGirl.create(:cropbot)
    end

    context "scientific names" do

      it "adds a scientific name to a crop that has none" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.scientific_names.size).to eq 0
        tomato.add_scientific_names_from_csv("Foo bar")
        expect(tomato.scientific_names.size).to eq 1
        expect(tomato.default_scientific_name).to eq "Foo bar"
      end

      it "picks up scientific name from parent crop if available" do
        parent = FactoryGirl.create(:crop, :name => 'parent crop')
        parent.add_scientific_names_from_csv("Parentis cropis")
        parent.save
        parent.reload

        tomato = FactoryGirl.create(:tomato, :parent => parent)
        expect(tomato.parent).to eq parent
        expect(tomato.parent.default_scientific_name).to eq "Parentis cropis"

        tomato.add_scientific_names_from_csv('')
        expect(tomato.default_scientific_name).to eq "Parentis cropis"
      end

      it "doesn't add a duplicate scientific name" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.scientific_names.size).to eq 0
        tomato.add_scientific_names_from_csv("Foo bar")
        expect(tomato.scientific_names.size).to eq 1
        tomato.add_scientific_names_from_csv("Foo bar")
        expect(tomato.scientific_names.size).to eq 1 # shouldn't increase
        tomato.add_scientific_names_from_csv("Baz quux")
        expect(tomato.scientific_names.size).to eq 2
      end

      it "doesn't add a duplicate scientific name from parent" do
        parent = FactoryGirl.create(:crop, :name => 'parent')
        parent.add_scientific_names_from_csv("Parentis cropis")
        parent.save
        parent.reload

        tomato = FactoryGirl.create(:tomato, :parent => parent)
        expect(tomato.scientific_names.size).to eq 0
        tomato.add_scientific_names_from_csv('')
        expect(tomato.scientific_names.size).to eq 1 # picks up parent SN
        tomato.add_scientific_names_from_csv('')
        expect(tomato.scientific_names.size).to eq 1 # shouldn't increase now
      end

      it "loads a crop with multiple scientific names" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.scientific_names.size).to eq 0
        tomato.add_scientific_names_from_csv("Foo, Bar")
        expect(tomato.scientific_names.size).to eq 2
        expect(tomato.scientific_names[0].scientific_name).to eq "Foo"
        expect(tomato.scientific_names[1].scientific_name).to eq "Bar"
      end

      it "loads multiple scientific names with variant spacing" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.scientific_names.size).to eq 0
        tomato.add_scientific_names_from_csv("Foo,Bar") # no space
        expect(tomato.scientific_names.size).to eq 2
        tomato.add_scientific_names_from_csv("Baz,   Quux") # multiple spaces
        expect(tomato.scientific_names.size).to eq 4
      end

    end # scientific names

    context "alternate names" do
      it "loads an alternate name" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.alternate_names.size).to eq 0
        tomato.add_alternate_names_from_csv("Foo")
        expect(tomato.alternate_names.size).to eq 1
        expect(tomato.alternate_names.last.name).to eq "Foo"
      end

      it "doesn't load duplicate alternate names" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.alternate_names.size).to eq 0
        tomato.add_alternate_names_from_csv("Foo")
        expect(tomato.alternate_names.size).to eq 1
        tomato.add_alternate_names_from_csv("Foo")
        expect(tomato.alternate_names.size).to eq 1 # still 1, doesn't add another
      end

      it "adds multiple alternate names" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.alternate_names.size).to eq 0
        tomato.add_alternate_names_from_csv("Foo, Bar")
        expect(tomato.alternate_names.size).to eq 2
        expect(tomato.alternate_names[0].name).to eq "Foo"
        expect(tomato.alternate_names[1].name).to eq "Bar"
      end

      it "adds multiple alt names with variant spacing" do
        tomato = FactoryGirl.create(:tomato)
        expect(tomato.alternate_names.size).to eq 0
        tomato.add_alternate_names_from_csv("Foo,Bar") # no space
        expect(tomato.alternate_names.size).to eq 2
        tomato.add_alternate_names_from_csv("Baz,   Quux") # mutliple spaces
        expect(tomato.alternate_names.size).to eq 4
      end
    end # alternate names

    it "loads the simplest possible crop" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato"

      CSV.parse(tomato_row) do |row|
        Crop.create_from_csv(row)
      end

      loaded = Crop.last
      expect(loaded.name).to eq "tomato"
      expect(loaded.en_wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Tomato'
      expect(loaded.creator).to eq @cropbot
    end

    it "loads a crop with a scientific name" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,,Solanum lycopersicum"

      CSV.parse(tomato_row) do |row|
        Crop.create_from_csv(row)
      end

      loaded = Crop.last
      expect(loaded.name).to eq "tomato"
      expect(loaded.scientific_names.size).to eq 1
      expect(loaded.scientific_names.last.scientific_name).to eq "Solanum lycopersicum"
    end

    it "loads a crop with an alternate name" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,,,Foo"

      CSV.parse(tomato_row) do |row|
        Crop.create_from_csv(row)
      end

      loaded = Crop.last
      expect(loaded.name).to eq "tomato"
      expect(loaded.alternate_names.size).to eq 1
      expect(loaded.alternate_names.last.name).to eq "Foo"
    end

    it "loads a crop with a parent" do
      parent = FactoryGirl.create(:crop, :name => 'parent')
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,parent"

      CSV.parse(tomato_row) do |row|
        Crop.create_from_csv(row)
      end

      loaded = Crop.last
      expect(loaded.parent).to eq parent
    end

    it "doesn't add unnecessary duplicate crops" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,,Solanum lycopersicum"

      CSV.parse(tomato_row) do |row|
        Crop.create_from_csv(row)
      end

      loaded = Crop.last
      expect(loaded.name).to eq "tomato"
      expect(loaded.en_wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Tomato'
      expect(loaded.creator).to eq @cropbot

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

  context "crop rejections" do
    let!(:rejected_reason) { FactoryGirl.create(:crop, :name => 'tomato', :approval_status => 'rejected', :reason_for_rejection => 'not edible') }
    let!(:rejected_other) { FactoryGirl.create(:crop, :name => 'tomato', :approval_status => 'rejected', :reason_for_rejection => 'other', :rejection_notes => 'blah blah blah') }

    describe "rejecting a crop" do
      it "should give reason if a default option" do
        expect(rejected_reason.rejection_explanation).to eq "not edible"
      end

      it "should show rejection notes if reason was other" do
        expect(rejected_other.rejection_explanation).to eq "blah blah blah"
      end
    end
  end
end
