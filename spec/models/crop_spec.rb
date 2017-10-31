require 'rails_helper'

describe Crop do
  context 'all fields present' do
    let(:crop) { FactoryBot.create(:tomato) }

    it 'should save a basic crop' do
      crop.save.should be(true)
    end

    it 'should be fetchable from the database' do
      crop.save
      @crop2 = Crop.find_by(name: 'tomato')
      @crop2.en_wikipedia_url.should eq("http://en.wikipedia.org/wiki/Tomato")
      @crop2.slug.should eq("tomato")
    end

    it 'should stringify as the system name' do
      crop.save
      crop.to_s.should eq('tomato')
    end

    it 'has a creator' do
      crop.save
      crop.creator.should be_an_instance_of Member
    end
  end

  context 'invalid data' do
    it 'should not save a crop without a system name' do
      crop = FactoryBot.build(:crop, name: nil)
      expect { crop.save }.to raise_error ActiveRecord::StatementInvalid
    end
  end

  context 'ordering' do
    before do
      @uppercase = FactoryBot.create(:uppercasecrop, created_at: 1.minute.ago)
      @lowercase = FactoryBot.create(:lowercasecrop, created_at: 2.days.ago)
    end

    it "should be sorted case-insensitively" do
      Crop.first.should == @lowercase
    end

    it 'recent scope sorts by creation date' do
      Crop.recent.first.should == @uppercase
    end
  end

  context 'popularity' do
    let(:tomato) { FactoryBot.create(:tomato) }
    let(:maize) { FactoryBot.create(:maize) }
    let(:cucumber) { FactoryBot.create(:crop, name: 'cucumber') }

    before do
      FactoryBot.create_list(:planting, 10, crop: maize)
      FactoryBot.create_list(:planting, 3, crop: tomato)
    end

    it "sorts by most plantings" do
      Crop.popular.first.should eq maize
      FactoryBot.create_list(:planting, 10, crop: tomato)
      Crop.popular.first.should eq tomato
    end
  end

  it 'finds a default scientific name' do
    @crop = FactoryBot.create(:tomato)
    @crop.default_scientific_name.should eq nil
    @sn = FactoryBot.create(:solanum_lycopersicum, crop: @crop)
    @crop.reload
    @crop.default_scientific_name.should eq @sn.name
  end

  it 'counts plantings' do
    @crop = FactoryBot.create(:tomato)
    @crop.plantings.size.should eq 0
    @planting = FactoryBot.create(:planting, crop: @crop)
    @crop.reload
    @crop.plantings.size.should eq 1
  end

  context "wikipedia url" do
    subject { FactoryBot.build(:tomato, en_wikipedia_url: wikipedia_url) }

    context 'not a url' do
      let(:wikipedia_url) { 'this is not valid' }
      it { expect(subject).not_to be_valid }
    end

    context 'http url' do
      let(:wikipedia_url) { 'http://en.wikipedia.org/wiki/SomePage' }
      it { expect(subject).to be_valid }
    end

    context 'with ssl' do
      let(:wikipedia_url) { 'https://en.wikipedia.org/wiki/SomePage' }
      it { expect(subject).to be_valid }
    end

    context 'with utf8 macrons' do
      let(:wikipedia_url) { 'https://en.wikipedia.org/wiki/Māori' }
      it { expect(subject).to be_valid }
    end

    context 'urlencoded' do
      let(:wikipedia_url) { 'https://en.wikipedia.org/wiki/M%C4%81ori' }
      it { expect(subject).to be_valid }
    end

    context 'with new lines in url' do
      let(:wikipedia_url) { 'http://en.wikipedia.org/wiki/SomePage\n\nBrendaRocks' }
      it { expect(subject).not_to be_valid }
    end

    context "with script tags in url" do
      let(:wikipedia_url) { 'http://en.wikipedia.org/wiki/SomePage<script>alert(\'BrendaRocks\')</script>' }
      it { expect(subject).not_to be_valid }
    end
  end

  context 'varieties' do
    it 'has a crop hierarchy' do
      @tomato = FactoryBot.create(:tomato)
      @roma = FactoryBot.create(:roma, parent_id: @tomato.id)
      @roma.parent.should eq @tomato
      @tomato.varieties.should eq [@roma]
    end

    it 'toplevel scope works' do
      @tomato = FactoryBot.create(:tomato)
      @roma = FactoryBot.create(:roma, parent_id: @tomato.id)
      Crop.toplevel.should eq [@tomato]
    end
  end

  context 'photos' do
    before :each do
      @crop = FactoryBot.create(:tomato)
    end
    context 'with a planting photo' do
      before :each do
        @planting = FactoryBot.create(:planting, crop: @crop)
        @photo = FactoryBot.create(:photo)
        @planting.photos << @photo
      end

      it 'has a default photo' do
        @crop.default_photo.should be_an_instance_of Photo
        @crop.default_photo.id.should eq @photo.id
      end

      it 'is found in has_photos scope' do
        Crop.has_photos.should include(@crop)
      end
    end

    context 'with a harvest photo' do
      before :each do
        @harvest = FactoryBot.create(:harvest, crop: @crop)
        @photo = FactoryBot.create(:photo)
        @harvest.photos << @photo
      end

      it 'has a default photo' do
        @crop.default_photo.should be_an_instance_of Photo
        @crop.default_photo.id.should eq @photo.id
      end

      context 'and planting photo' do
        before :each do
          @planting = FactoryBot.create(:planting, crop: @crop)
          @planting_photo = FactoryBot.create(:photo)
          @planting.photos << @planting_photo
        end

        it 'should prefer the planting photo' do
          @crop.default_photo.id.should eq @planting_photo.id
        end
      end
    end

    context 'with no plantings or harvests' do
      it 'has no default photo' do
        @crop.default_photo.should eq nil
      end
    end
  end

  context 'sunniness' do
    let(:crop) { FactoryBot.create(:tomato) }

    it 'returns a hash of sunniness values' do
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:semi_shady_planting, crop: crop)
      FactoryBot.create(:shady_planting, crop: crop)
      crop.sunniness.should be_an_instance_of Hash
    end

    it 'counts each sunniness value' do
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:semi_shady_planting, crop: crop)
      FactoryBot.create(:shady_planting, crop: crop)
      crop.sunniness.should == { 'sun' => 2, 'shade' => 1, 'semi-shade' => 1 }
    end

    it 'ignores unused sunniness values' do
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:sunny_planting, crop: crop)
      FactoryBot.create(:semi_shady_planting, crop: crop)
      crop.sunniness.should == { 'sun' => 2, 'semi-shade' => 1 }
    end
  end

  context 'planted_from' do
    let(:crop) { FactoryBot.create(:tomato) }

    it 'returns a hash of sunniness values' do
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seedling_planting, crop: crop)
      FactoryBot.create(:cutting_planting, crop: crop)
      crop.planted_from.should be_an_instance_of Hash
    end

    it 'counts each planted_from value' do
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seedling_planting, crop: crop)
      FactoryBot.create(:cutting_planting, crop: crop)
      crop.planted_from.should == { 'seed' => 2, 'seedling' => 1, 'cutting' => 1 }
    end

    it 'ignores unused planted_from values' do
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seed_planting, crop: crop)
      FactoryBot.create(:seedling_planting, crop: crop)
      crop.planted_from.should == { 'seed' => 2, 'seedling' => 1 }
    end
  end

  context 'popular plant parts' do
    let(:crop) { FactoryBot.create(:tomato) }

    it 'returns a hash of plant_part values' do
      crop.popular_plant_parts.should be_an_instance_of Hash
    end

    it 'counts each plant_part value' do
      @fruit = FactoryBot.create(:plant_part)
      @seed = FactoryBot.create(:plant_part, name: 'seed')
      @root = FactoryBot.create(:plant_part, name: 'root')
      @bulb = FactoryBot.create(:plant_part, name: 'bulb')
      @harvest1 = FactoryBot.create(:harvest,
        crop: crop,
        plant_part: @fruit)
      @harvest2 = FactoryBot.create(:harvest,
        crop: crop,
        plant_part: @fruit)
      @harvest3 = FactoryBot.create(:harvest,
        crop: crop,
        plant_part: @seed)
      @harvest4 = FactoryBot.create(:harvest,
        crop: crop,
        plant_part: @root)
      crop.popular_plant_parts.should == { [@fruit.id, @fruit.name] => 2,
                                           [@seed.id, @seed.name] => 1,
                                           [@root.id, @root.name] => 1 }
    end
  end

  context 'interesting' do
    it 'lists interesting crops' do
      # first, a couple of candidate crops
      @crop1 = FactoryBot.create(:crop)
      @crop2 = FactoryBot.create(:crop)

      # they need 3+ plantings each to be interesting
      (1..3).each do
        FactoryBot.create(:planting, crop: @crop1)
      end
      (1..3).each do
        FactoryBot.create(:planting, crop: @crop2)
      end

      # crops need 3+ photos to be interesting
      @photo = FactoryBot.create(:photo)
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
      @crop1 = FactoryBot.create(:crop)
      @crop2 = FactoryBot.create(:crop)

      # only crop1 has plantings
      (1..3).each do
        FactoryBot.create(:planting, crop: @crop1)
      end

      # ... and photos
      @photo = FactoryBot.create(:photo)
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
      @crop1 = FactoryBot.create(:crop)
      @crop2 = FactoryBot.create(:crop)

      # both crops have plantings
      (1..3).each do
        FactoryBot.create(:planting, crop: @crop1)
      end
      (1..3).each do
        FactoryBot.create(:planting, crop: @crop2)
      end

      # but only crop1 has photos
      @photo = FactoryBot.create(:photo)
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
      crop = FactoryBot.create(:crop)
      harvest = FactoryBot.create(:harvest, crop: crop)
      crop.harvests.should eq [harvest]
    end
  end

  it 'has plant_parts' do
    @maize = FactoryBot.create(:maize)
    @pp1 = FactoryBot.create(:plant_part)
    @pp2 = FactoryBot.create(:plant_part)
    @h1 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @h2 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp2)
    @maize.plant_parts.should include @pp1
    @maize.plant_parts.should include @pp2
  end

  it "doesn't duplicate plant_parts" do
    @maize = FactoryBot.create(:maize)
    @pp1 = FactoryBot.create(:plant_part)
    @h1 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @h2 = FactoryBot.create(:harvest,
      crop: @maize,
      plant_part: @pp1)
    @maize.plant_parts.should eq [@pp1]
  end

  context "search", :elasticsearch do
    let(:mushroom) { FactoryBot.create(:crop, name: 'mushroom') }

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
      @rejected_crop = FactoryBot.create(:rejected_crop, name: 'tomato')
      sync_elasticsearch([@rejected_crop])
      Crop.search('tomato').should_not include @rejected_crop
    end
    it "doesn't find 'pending' crop" do
      @crop_request = FactoryBot.create(:crop_request, name: 'tomato')
      sync_elasticsearch([@crop_request])
      Crop.search('tomato').should_not include @crop_request
    end
  end

  context "csv loading" do
    before(:each) do
      # don't use 'let' for this -- we need to actually create it,
      # regardless of whether it's used.
      @cropbot = FactoryBot.create(:cropbot)
    end

    context "scientific names" do
      it "adds a scientific name to a crop that has none" do
        row = ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Foo bar"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.scientific_names.size).to eq 1
        expect(tomato.default_scientific_name).to eq "Foo bar"
      end

      it "picks up scientific name from parent crop if available" do
        parent = CsvImporter.new.import_crop(
          ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Parentis cropis"]
        )

        tomato = CsvImporter.new.import_crop(
          ["Tomato", "http://en.wikipedia.org/wiki/Parent", "parent"]
        )

        expect(tomato.parent).to eq parent
        expect(tomato.parent.default_scientific_name).to eq "Parentis cropis"
        expect(tomato.default_scientific_name).to eq "Parentis cropis"
      end

      it "doesn't add a duplicate scientific name" do
        row = ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Foo bar, Foo bar"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.scientific_names.size).to eq 1
      end

      it "doesn't add a duplicate scientific name from parent" do
        CsvImporter.new.import_crop(
          ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Parentis cropis"]
        )
        tomato = CsvImporter.new.import_crop(
          ["Tomato", "http://en.wikipedia.org/wiki/Parent", "parent", "Parentis cropis"]
        )
        expect(tomato.scientific_names.size).to eq 1
      end

      it "loads a crop with multiple scientific names" do
        row = ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Foo,Bar"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.scientific_names[0].name).to eq "Foo"
        expect(tomato.scientific_names[1].name).to eq "Bar"
      end

      it "loads multiple scientific names with variant spacing" do
        row = ["parent", "http://en.wikipedia.org/wiki/Parent", "", "Baz,   Quux"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.scientific_names.size).to eq 2
        expect(tomato.scientific_names[0].name).to eq "Baz"
        expect(tomato.scientific_names[1].name).to eq "Quux"
      end
    end # scientific names

    context "alternate names" do
      it "loads an alternate name" do
        row = ["tomato", "http://en.wikipedia.org/wiki/Parent", "", "", "Foo"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.alternate_names.size).to eq 1
        expect(tomato.alternate_names.last.name).to eq "Foo"
      end

      it "adds multiple alternate names" do
        row = ["tomato", "http://en.wikipedia.org/wiki/Parent", "", "", "Foo, Bar"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.alternate_names.size).to eq 2
        expect(tomato.alternate_names[0].name).to eq "Foo"
        expect(tomato.alternate_names[1].name).to eq "Bar"
      end

      it "adds multiple alt names with variant spacing" do
        row = ["tomato", "http://en.wikipedia.org/wiki/Parent", "", "", "Foo,Bar,Baz,   Quux"]
        tomato = CsvImporter.new.import_crop(row)
        expect(tomato.alternate_names.size).to eq 4
        expect(tomato.alternate_names[0].name).to eq "Foo"
        expect(tomato.alternate_names[1].name).to eq "Bar"
        expect(tomato.alternate_names[2].name).to eq "Baz"
        expect(tomato.alternate_names[3].name).to eq "Quux"
      end

      it "Adds a duplicate alternate name for second crop" do
        row = ["tomato", "http://en.wikipedia.org/wiki/tomato", "", "", "Foo"]
        tomato = CsvImporter.new.import_crop(row)
        row = ["tomoto", "http://en.wikipedia.org/wiki/tomoto", "", "", "Foo"]
        tomoto = CsvImporter.new.import_crop(row)
        expect(tomato.alternate_names.size).to eq 1
        expect(tomoto.alternate_names.size).to eq 1
      end
    end # alternate names

    it "loads the simplest possible crop" do
      tomato_row = ["tomato", "http://en.wikipedia.org/wiki/Tomato"]
      tomato = CsvImporter.new.import_crop(tomato_row)

      expect(tomato.name).to eq "tomato"
      expect(tomato.en_wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Tomato'
      expect(tomato.creator).to eq @cropbot
    end

    it "loads a crop with a scientific name" do
      tomato_row = ["tomato", "http://en.wikipedia.org/wiki/Tomato", "", "Solanum lycopersicum"]
      tomato = CsvImporter.new.import_crop(tomato_row)

      expect(tomato.name).to eq "tomato"
      expect(tomato.scientific_names.size).to eq 1
      expect(tomato.scientific_names.last.name).to eq "Solanum lycopersicum"
    end

    it "loads a crop with an alternate name" do
      crop = CsvImporter.new.import_crop(
        ["tomato", "http://en.wikipedia.org/wiki/Tomato", nil, nil, "Foo"]
      )

      expect(crop.name).to eq "tomato"
      expect(crop.alternate_names.size).to eq 1
      expect(crop.alternate_names.last.name).to eq "Foo"
    end

    it "loads a crop with a parent" do
      parent = FactoryBot.create(:crop, name: 'parent')
      crop = CsvImporter.new.import_crop(
        ["tomato", "http://en.wikipedia.org/wiki/Tomato", "parent"]
      )
      expect(crop.parent).to eq parent
    end

    it "loads a crop with a missing parent" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,parent"

      CSV.parse(tomato_row) do |row|
        CsvImporter.new.import_crop(row)
      end

      loaded = Crop.last
      expect(loaded.parent).to be_nil
    end

    it "doesn't add unnecessary duplicate crops" do
      tomato_row = "tomato,http://en.wikipedia.org/wiki/Tomato,,Solanum lycopersicum"

      CSV.parse(tomato_row) do |row|
        CsvImporter.new.import_crop(row)
      end

      loaded = Crop.last
      expect(loaded.name).to eq "tomato"
      expect(loaded.en_wikipedia_url).to eq 'http://en.wikipedia.org/wiki/Tomato'
      expect(loaded.creator).to eq @cropbot
    end
  end

  context "crop-post association" do
    let!(:tomato) { FactoryBot.create(:tomato) }
    let!(:maize) { FactoryBot.create(:maize) }
    let!(:post) { FactoryBot.create(:post, body: "[maize](crop)[tomato](crop)[tomato](crop)") }

    describe "destroying a crop" do
      before do
        tomato.destroy
      end

      it "should delete the association between post and the crop(tomato)" do
        expect(Post.find(post.id).crops).to eq [maize]
      end

      it "should not delete the posts" do
        expect(Post.find(post.id)).to_not eq nil
      end
    end
  end

  context "crop rejections" do
    let!(:rejected_reason) do
      FactoryBot.create(:crop, name: 'tomato',
                                approval_status: 'rejected',
                                reason_for_rejection: 'not edible')
    end
    let!(:rejected_other) do
      FactoryBot.create(:crop, name: 'tomato',
                                approval_status: 'rejected',
                                reason_for_rejection: 'other',
                                rejection_notes: 'blah blah blah')
    end

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
