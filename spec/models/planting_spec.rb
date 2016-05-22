require 'rails_helper'

describe Planting do

  let(:crop) { FactoryGirl.create(:tomato) }
  let(:garden_owner) { FactoryGirl.create(:member) }
  let(:garden) { FactoryGirl.create(:garden, owner: garden_owner) }
  let(:planting) { FactoryGirl.create(:planting,
      crop: crop, garden: garden)}

  it 'has an owner' do
    planting.owner.should be_an_instance_of Member
  end

  it "owner isn't necessarily the garden owner" do
    # a new owner should be created automatically by FactoryGirl
    # note that formerly, the planting belonged to an owner through the garden
    planting.owner.should_not eq garden_owner
  end

  it "generates a location" do
    planting.location.should eq "#{garden_owner.login_name}'s #{garden.name}"
  end

  it "sorts plantings in descending order of creation" do
    @planting1 = FactoryGirl.create(:planting)
    @planting2 = FactoryGirl.create(:planting)
    Planting.first.should eq @planting2
  end

  it "should have a slug" do
    planting.slug.should match /^member\d+-springfield-community-garden-tomato$/
  end

  it 'should sort in reverse creation order' do
    @planting2 = FactoryGirl.create(:planting)
    Planting.first.should eq @planting2
  end

  describe '#planted?' do
    it "should be false for future plantings"
    it "should be false for never planted"
    it "should be false for future plantings"
  end

  describe '#percentage_grown' do
    it 'should not be more than 100%' do
      @planting = FactoryGirl.build(:planting, days_before_maturity: 1, planted_at: 1.day.ago)

      now_later_than_planting = 2.days.from_now

      @planting.percentage_grown(now_later_than_planting).should be 100
    end

    it 'should not be less than 0%' do
      @planting = FactoryGirl.build(:planting, days_before_maturity: 1, planted_at: 1.day.ago)

      now_earlier_than_planting = 2.days.ago

      @planting.percentage_grown(now_earlier_than_planting).should be nil
    end

    it 'should reflect the current growth' do
      @planting = FactoryGirl.build(:planting, days_before_maturity: 10, planted_at: 4.days.ago)

      expect(@planting.percentage_grown(Date.current)).to eq 40
    end

    it 'should not be calculated for unplanted plantings' do
      @planting = FactoryGirl.build(:planting, planted_at: nil)

      @planting.planted?.should be false
      @planting.percentage_grown.should be nil
    end

    it 'should not be calculated for plantings with an unknown days before maturity' do
      @planting = FactoryGirl.build(:planting, days_before_maturity: nil)

      @planting.percentage_grown.should be nil    
    end
  end

  context 'delegation' do
    it 'system name' do
      planting.crop_name.should eq planting.crop.name
    end

    it 'wikipedia url' do
      planting.crop_en_wikipedia_url.should eq planting.crop.en_wikipedia_url
    end

    it 'default scientific name' do
      planting.crop_default_scientific_name.should eq planting.crop.default_scientific_name
    end

    it 'plantings count' do
      planting.crop_plantings_count.should eq planting.crop.plantings_count
    end
  end

  context 'quantity' do
    it 'allows integer quantities' do
      @planting = FactoryGirl.build(:planting, quantity: 99)
      @planting.should be_valid
    end

    it "doesn't allow decimal quantities" do
      @planting = FactoryGirl.build(:planting, quantity: 99.9)
      @planting.should_not be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @planting = FactoryGirl.build(:planting, quantity: 'foo')
      @planting.should_not be_valid
    end

    it "allows blank quantities" do
      @planting = FactoryGirl.build(:planting, quantity: nil)
      @planting.should be_valid
      @planting = FactoryGirl.build(:planting, quantity: '')
      @planting.should be_valid
    end
  end

  context 'sunniness' do

    let(:planting) { FactoryGirl.create(:sunny_planting) }

    it 'should have a sunniness value' do
      planting.sunniness.should eq 'sun'
    end

    it 'all three valid sunniness values should work' do
      ['sun', 'shade', 'semi-shade', nil, ''].each do |s|
        @planting = FactoryGirl.build(:planting, sunniness: s)
        @planting.should be_valid
      end
    end

    it 'should refuse invalid sunniness values' do
      @planting = FactoryGirl.build(:planting, sunniness: 'not valid')
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
        'graft', 'layering', 'bulb', 'root/tuber', nil, ''].each do |p|
        @planting = FactoryGirl.build(:planting, planted_from: p)
        @planting.should be_valid
      end
    end

    it 'should refuse invalid planted_from values' do
      @planting = FactoryGirl.build(:planting, planted_from: 'not valid')
      @planting.should_not be_valid
      @planting.errors[:planted_from].should include("not valid is not a valid planting method")
    end
  end

  # we decided that all the tests for the planting/photo association would
  # be done on this side, not on the photos side
  context 'photos' do

    let(:planting) { FactoryGirl.create(:planting) }
    let(:photo) { FactoryGirl.create(:photo) }

    before do
      planting.photos << photo
    end

    it 'has a photo' do
      planting.photos.first.should eq photo
    end

    it 'deletes association with photos when photo is deleted' do
      photo.destroy
      planting.reload
      planting.photos.should be_empty
    end

    it 'has a default photo' do
      planting.default_photo.should eq photo
    end

    it 'chooses the most recent photo' do
      @photo2 = FactoryGirl.create(:photo)
      planting.photos << @photo2
      planting.default_photo.should eq @photo2
    end
  end

  context 'interesting plantings' do
    it 'picks up interesting plantings' do
      # plantings have members created implicitly for them
      # each member is different, hence these are all interesting
      @planting1 = FactoryGirl.create(:planting, created_at: 5.days.ago)
      @planting2 = FactoryGirl.create(:planting, created_at: 4.days.ago)
      @planting3 = FactoryGirl.create(:planting, created_at: 3.days.ago)
      @planting4 = FactoryGirl.create(:planting, created_at: 2.days.ago)

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

    context "default arguments" do
      it 'ignores plantings without photos' do
        # first, an interesting planting
        @planting = FactoryGirl.create(:planting)
        @planting.photos << FactoryGirl.create(:photo)
        @planting.save

        # this one doesn't have a photo
        @no_photo_planting = FactoryGirl.create(:planting)

        Planting.interesting.should include @planting
        Planting.interesting.should_not include @no_photo_planting
      end

      it 'ignores plantings with the same owner' do
        # this planting is older
        @planting1 = FactoryGirl.create(:planting, created_at: 1.day.ago)
        @planting1.photos << FactoryGirl.create(:photo)
        @planting1.save

        # this one is newer, and has the same owner, through the garden
        @planting2 = FactoryGirl.create(:planting,
          created_at: 1.minute.ago,
          owner_id: @planting1.owner.id
        )
        @planting2.photos << FactoryGirl.create(:photo)
        @planting2.save

        # result: the newer one is interesting, the older one isn't
        Planting.interesting.should include @planting2
        Planting.interesting.should_not include @planting1
      end
    end

    context "with require_photo = false" do
      it "returns plantings without photos" do
        # first, a planting with a photo
        @planting = FactoryGirl.create(:planting)
        @planting.photos << FactoryGirl.create(:photo)
        @planting.save

        # this one doesn't have a photo
        @no_photo_planting = FactoryGirl.create(:planting)

        interesting = Planting.interesting(10, false)
        interesting.should include @planting
        interesting.should include @no_photo_planting
      end
    end

    context "with howmany argument" do
      it "only returns the number asked for" do
        @plantings = FactoryGirl.create_list(:planting, 10)
        Planting.interesting(3, false).size.should eq 3
      end
    end

  end # interesting plantings

  context "finished" do
    it 'has finished fields' do
      @planting = FactoryGirl.create(:finished_planting)
      @planting.finished.should be true
      @planting.finished_at.should be_an_instance_of Date
    end

    it 'has finished scope' do
      @p = FactoryGirl.create(:planting)
      @f = FactoryGirl.create(:finished_planting)
      Planting.finished.should include @f
      Planting.finished.should_not include @p
    end

    it 'has current scope' do
      @p = FactoryGirl.create(:planting)
      @f = FactoryGirl.create(:finished_planting)
      Planting.current.should include @p
      Planting.current.should_not include @f
    end

    context "finished date validation" do
      it 'requires finished date after planting date' do
        @f = FactoryGirl.build(:finished_planting, planted_at:             '2014-01-01', finished_at: '2013-01-01')
        @f.should_not be_valid
      end

      it 'allows just the planted date' do
        @f = FactoryGirl.build(:planting, planted_at: '2013-01-01', finished_at: nil)
        @f.should be_valid
      end

      it 'allows just the finished date' do
        @f = FactoryGirl.build(:planting, finished_at: '2013-01-01', planted_at: nil)
        @f.should be_valid
      end
    end
  end
end
