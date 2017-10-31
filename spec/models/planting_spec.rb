require 'rails_helper'

describe Planting do
  let(:crop) { FactoryBot.create(:tomato) }
  let(:garden_owner) { FactoryBot.create(:member) }
  let(:garden) { FactoryBot.create(:garden, owner: garden_owner) }
  let(:planting) { FactoryBot.create(:planting, crop: crop, garden: garden) }
  let(:finished_planting) { FactoryBot.create :planting, planted_at: 4.days.ago, finished_at: 2.days.ago }

  describe 'maturity calculations' do
    describe 'start_to_finish_diff' do
      it { expect(finished_planting.start_to_finish_diff).to eq(2) }
    end

    describe 'other_finished_plantings_same_crop' do
      before do
        # eight finished plantings
        8.times { FactoryBot.create :planting, crop: crop, planted_at: 10.days.ago, finished_at: 2.days.ago }
        # eight not finished plantings
        8.times { FactoryBot.create :planting, crop: crop, finished_at: nil }
      end
      let!(:planting_with_diff_crop) { FactoryBot.create :planting, planted_at: 10.days.ago, finished_at: 2.days.ago }
      let(:planting_predictions) { PlantingPredictions.new(planting) }
      it { expect(planting_predictions.send(:other_finished_plantings_same_crop).size).to eq(8) }
      it { expect(planting_predictions.send(:other_finished_plantings_same_crop)).not_to include(planting) }
      it do
        expect(planting_predictions.send(:other_finished_plantings_same_crop))
          .not_to include(planting_with_diff_crop)
      end
    end

    describe 'mean_days_until_maturity' do
      let(:plantings) do
        FactoryBot.create_list(:planting, 10, crop: crop, planted_at: 12.days.ago, finished_at: 2.days.ago)
      end
      it { expect(plantings.size).to eq(10) }
      it { expect(PlantingPredictions.mean_days_until_maturity(plantings)).to eq(10) }
    end

    describe 'saving planting calculates days_before_maturity' do
      before { 5.times { FactoryBot.create :planting, planted_at: 30.days.ago, finished_at: 9.days.ago, crop: crop } }
      before { planting.calc_and_set_days_before_maturity }
      it { expect(planting.days_before_maturity).to eq(21) }
    end
  end

  it 'has an owner' do
    planting.owner.should be_an_instance_of Member
  end

  it "owner isn't necessarily the garden owner" do
    # a new owner should be created automatically by FactoryBot
    # note that formerly, the planting belonged to an owner through the garden
    planting.owner.should_not eq garden_owner
  end

  it "generates a location" do
    planting.location.should eq "#{garden_owner.login_name}'s #{garden.name}"
  end

  it "sorts plantings in descending order of creation" do
    @planting1 = FactoryBot.create(:planting)
    @planting2 = FactoryBot.create(:planting)
    Planting.first.should eq @planting2
  end

  it "should have a slug" do
    planting.slug.should match(/^member\d+-springfield-community-garden-tomato$/)
  end

  it 'should sort in reverse creation order' do
    @planting2 = FactoryBot.create(:planting)
    Planting.first.should eq @planting2
  end

  describe '#planted?' do
    it "should be false for future plantings" do
      planting = FactoryBot.create :planting, planted_at: Time.zone.today + 1
      expect(planting.planted?).to eq(false)
    end
    it "should be false for never planted" do
      planting = FactoryBot.create :planting, planted_at: nil
      expect(planting.planted?).to eq(false)
    end
    it "should be true for past plantings" do
      planting = FactoryBot.create :planting, planted_at: Time.zone.today - 1
      expect(planting.planted?).to eq(true)
    end
  end

  describe '#percentage_grown' do
    it 'should not be more than 100%' do
      @planting = FactoryBot.build(:planting, days_before_maturity: 1, planted_at: 1.day.ago)

      Timecop.freeze(2.days.from_now) do
        @planting.percentage_grown.should be 100
      end
    end

    it 'should not be less than 0%' do
      @planting = FactoryBot.build(:planting, days_before_maturity: 1, planted_at: 1.day.ago)

      Timecop.freeze(2.days.ago) do
        @planting.percentage_grown.should be nil
      end
    end

    it 'should reflect the current growth' do
      @planting = FactoryBot.build(:planting, days_before_maturity: 10, planted_at: 4.days.ago)
      expect(@planting.percentage_grown).to eq 40
    end

    it 'should not be calculated for unplanted plantings' do
      @planting = FactoryBot.build(:planting, planted_at: nil)

      @planting.planted?.should be false
      @planting.percentage_grown.should be nil
    end

    it 'should not be calculated for plantings with an unknown days before maturity' do
      @planting = FactoryBot.build(:planting, days_before_maturity: nil)
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
      @planting = FactoryBot.build(:planting, quantity: 99)
      @planting.should be_valid
    end

    it "doesn't allow decimal quantities" do
      @planting = FactoryBot.build(:planting, quantity: 99.9)
      @planting.should_not be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @planting = FactoryBot.build(:planting, quantity: 'foo')
      @planting.should_not be_valid
    end

    it "allows blank quantities" do
      @planting = FactoryBot.build(:planting, quantity: nil)
      @planting.should be_valid
      @planting = FactoryBot.build(:planting, quantity: '')
      @planting.should be_valid
    end
  end

  context 'sunniness' do
    let(:planting) { FactoryBot.create(:sunny_planting) }

    it 'should have a sunniness value' do
      planting.sunniness.should eq 'sun'
    end

    it 'all three valid sunniness values should work' do
      ['sun', 'shade', 'semi-shade', nil, ''].each do |s|
        @planting = FactoryBot.build(:planting, sunniness: s)
        @planting.should be_valid
      end
    end

    it 'should refuse invalid sunniness values' do
      @planting = FactoryBot.build(:planting, sunniness: 'not valid')
      @planting.should_not be_valid
      @planting.errors[:sunniness].should include("not valid is not a valid sunniness value")
    end
  end

  context 'planted from' do
    it 'should have a planted_from value' do
      @planting = FactoryBot.create(:seed_planting)
      @planting.planted_from.should eq 'seed'
    end

    it 'all valid planted_from values should work' do
      ['seed', 'seedling', 'cutting', 'root division',
       'runner', 'bare root plant', 'advanced plant',
       'graft', 'layering', 'bulb', 'root/tuber', nil, ''].each do |p|
        @planting = FactoryBot.build(:planting, planted_from: p)
        @planting.should be_valid
      end
    end

    it 'should refuse invalid planted_from values' do
      @planting = FactoryBot.build(:planting, planted_from: 'not valid')
      @planting.should_not be_valid
      @planting.errors[:planted_from].should include("not valid is not a valid planting method")
    end
  end

  # we decided that all the tests for the planting/photo association would
  # be done on this side, not on the photos side
  context 'photos' do
    let(:planting) { FactoryBot.create(:planting) }
    let(:photo) { FactoryBot.create(:photo) }

    before do
      planting.photos << photo
    end

    it 'has a photo' do
      planting.photos.first.should eq photo
    end

    it 'is found in has_photos scope' do
      Planting.has_photos.should include(planting)
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
      @photo2 = FactoryBot.create(:photo)
      planting.photos << @photo2
      planting.default_photo.should eq @photo2
    end
  end

  context 'interesting plantings' do
    it 'picks up interesting plantings' do
      # plantings have members created implicitly for them
      # each member is different, hence these are all interesting
      @planting1 = FactoryBot.create(:planting, created_at: 5.days.ago)
      @planting2 = FactoryBot.create(:planting, created_at: 4.days.ago)
      @planting3 = FactoryBot.create(:planting, created_at: 3.days.ago)
      @planting4 = FactoryBot.create(:planting, created_at: 2.days.ago)

      # plantings need photos to be interesting
      @photo = FactoryBot.create(:photo)
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
        @planting = FactoryBot.create(:planting)
        @planting.photos << FactoryBot.create(:photo)
        @planting.save

        # this one doesn't have a photo
        @no_photo_planting = FactoryBot.create(:planting)

        Planting.interesting.should include @planting
        Planting.interesting.should_not include @no_photo_planting
      end

      it 'ignores plantings with the same owner' do
        # this planting is older
        @planting1 = FactoryBot.create(:planting, created_at: 1.day.ago)
        @planting1.photos << FactoryBot.create(:photo)
        @planting1.save

        # this one is newer, and has the same owner, through the garden
        @planting2 = FactoryBot.create(:planting,
          created_at: 1.minute.ago,
          owner_id: @planting1.owner.id)
        @planting2.photos << FactoryBot.create(:photo)
        @planting2.save

        # result: the newer one is interesting, the older one isn't
        Planting.interesting.should include @planting2
        Planting.interesting.should_not include @planting1
      end
    end

    context "with howmany argument" do
      it "only returns the number asked for" do
        @plantings = FactoryBot.create_list(:planting, 10)
        @plantings.each do |p|
          p.photos << FactoryBot.create(:photo, owner: planting.owner)
        end
        Planting.interesting.limit(3).count.should eq 3
      end
    end
  end # interesting plantings

  context "finished" do
    it 'has finished fields' do
      @planting = FactoryBot.create(:finished_planting)
      @planting.finished.should be true
      @planting.finished_at.should be_an_instance_of Date
    end

    it 'has finished scope' do
      @p = FactoryBot.create(:planting)
      @f = FactoryBot.create(:finished_planting)
      Planting.finished.should include @f
      Planting.finished.should_not include @p
    end

    it 'has current scope' do
      @p = FactoryBot.create(:planting)
      @f = FactoryBot.create(:finished_planting)
      Planting.current.should include @p
      Planting.current.should_not include @f
    end

    context "finished date validation" do
      it 'requires finished date after planting date' do
        @f = FactoryBot.build(:finished_planting, planted_at: '2014-01-01', finished_at: '2013-01-01')
        @f.should_not be_valid
      end

      it 'allows just the planted date' do
        @f = FactoryBot.build(:planting, planted_at: '2013-01-01', finished_at: nil)
        @f.should be_valid
      end

      it 'allows just the finished date' do
        @f = FactoryBot.build(:planting, finished_at: '2013-01-01', planted_at: nil)
        @f.should be_valid
      end
    end
  end

  it 'excludes deleted members' do
    expect(Planting.joins(:owner).all).to include(planting)
    planting.owner.destroy
    expect(Planting.joins(:owner).all).not_to include(planting)
  end
end
