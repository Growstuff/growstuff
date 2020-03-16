# frozen_string_literal: true

require 'rails_helper'

describe Planting do
  let(:crop)         { FactoryBot.create(:tomato)                                                            }
  let(:garden_owner) { FactoryBot.create(:member, login_name: 'hatupatu')                                    }
  let(:garden)       { FactoryBot.create(:garden, owner: garden_owner, name: 'Springfield Community Garden') }
  let(:planting)     { FactoryBot.create(:planting, crop: crop, garden: garden, owner: garden.owner)         }

  describe 'planting lifespan predictions' do
    context 'no predications data yet' do
      describe 'planting planted, not finished' do
        let(:planting) { FactoryBot.create :planting, planted_at: 30.days.ago, finished_at: nil, finished: false }

        it { expect(planting.crop.median_lifespan).to eq(nil) }
        it { expect(planting.expected_lifespan).to eq(nil) }
        it { expect(planting.age_in_days).to eq(30) }
        it { expect(planting.percentage_grown).to eq(nil) }
      end

      describe 'planting not planted yet' do
        let(:planting) { FactoryBot.create :planting, planted_at: nil, finished_at: nil, finished: false }

        it { expect(planting.crop.median_lifespan).to eq(nil) }
        it { expect(planting.expected_lifespan).to eq(nil) }
        it { expect(planting.age_in_days).to eq(nil) }
        it { expect(planting.percentage_grown).to eq(0) }
      end

      describe 'planting finished, no planted_at' do
        let(:planting) { FactoryBot.create :planting, planted_at: nil, finished_at: 1.day.ago, finished: true }

        it { expect(planting.crop.median_lifespan).to eq(nil) }
        it { expect(planting.expected_lifespan).to eq(nil) }
        it { expect(planting.age_in_days).to eq(nil) }
        it { expect(planting.percentage_grown).to eq(100) }
      end

      describe 'planting all finished' do
        let(:planting) { FactoryBot.create :planting, planted_at: 30.days.ago, finished_at: 10.days.ago, finished: true }

        it { expect(planting.crop.median_lifespan).to eq(nil) }
        it { expect(planting.expected_lifespan).to eq(20) }
        it { expect(planting.age_in_days).to eq(20) }
        it { expect(planting.percentage_grown).to eq(100) }
      end
    end

    context 'lots of data' do
      before do
        FactoryBot.create :planting, crop: planting.crop, planted_at: 10.days.ago
        FactoryBot.create :planting, crop: planting.crop, planted_at: 100.days.ago, finished_at: 50.days.ago
        FactoryBot.create :planting, crop: planting.crop, planted_at: 100.days.ago, finished_at: 51.days.ago
        FactoryBot.create :planting, crop: planting.crop, planted_at: 2.years.ago, finished_at: 50.days.ago
        FactoryBot.create :planting, crop: planting.crop, planted_at: 150.days.ago, finished_at: 100.days.ago
        planting.crop.update_lifespan_medians
      end

      it { expect(planting.crop.median_lifespan).to eq 50 }

      describe 'planting 30 days ago, not finished' do
        let(:planting) { FactoryBot.create :planting, planted_at: 30.days.ago }

        # 30 / 50 = 60%
        it { expect(planting.percentage_grown).to eq 60.0 }
        # planted 30 days ago
        it { expect(planting.age_in_days).to eq 30 }
        # means 20 days to go
        it { expect(planting.finish_predicted_at).to eq Time.zone.today + 20.days }
      end

      describe 'child crop uses parent data' do
        let(:child_crop)     { FactoryBot.create :crop, parent: crop, name: 'child'                   }
        let(:child_planting) { FactoryBot.create :planting, crop: child_crop, planted_at: 30.days.ago }

        # not data for this crop
        it { expect(child_crop.median_lifespan).to eq nil }
        # 30 / 50 = 60%
        it { expect(child_planting.percentage_grown).to eq 60.0 }
        # planted 30 days ago
        it { expect(child_planting.age_in_days).to eq 30 }
        # means 20 days to go
        it { expect(child_planting.finish_predicted_at).to eq Time.zone.today + 20.days }
      end

      describe 'planting not planted yet' do
        let(:planting) { FactoryBot.create :planting, planted_at: nil, finished_at: nil }

        it { expect(planting.percentage_grown).to eq 0 }
      end

      describe 'planting finished 10 days, but was never planted' do
        let(:planting) { FactoryBot.create :planting, planted_at: nil, finished_at: 10.days.ago }

        it { expect(planting.percentage_grown).to eq 100 }
      end

      describe 'planted 30 days ago, finished 10 days ago' do
        let(:planting) { FactoryBot.create :planting, planted_at: 30.days.ago, finished_at: 10.days.ago }

        it { expect(planting.age_in_days).to eq 20 }
        it { expect(planting.percentage_grown).to eq 100 }
      end
    end
  end

  describe 'planting first harvest preductions' do
    context 'no data' do
      let(:planting) { FactoryBot.create :planting }

      it { expect(planting.crop.median_days_to_first_harvest).to eq(nil) }
      it { expect(planting.crop.median_days_to_last_harvest).to eq(nil) }
      it { expect(planting.days_to_first_harvest).to eq(nil) }
      it { expect(planting.days_to_last_harvest).to eq(nil) }
      it { expect(planting.expected_lifespan).to eq(nil) }
    end

    context 'lots of data' do
      let(:crop) { FactoryBot.create :crop }
      # this is a method so it creates a new one each time

      def one_hundred_day_old_planting
        FactoryBot.create(:planting, crop: crop, planted_at: 100.days.ago)
      end
      before do
        # 50 days to harvest
        FactoryBot.create(:harvest, harvested_at: 50.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)
        # 20 days to harvest
        FactoryBot.create(:harvest, harvested_at: 80.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)
        # 10 days to harvest
        FactoryBot.create(:harvest, harvested_at: 90.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)

        planting.crop.plantings.each(&:update_harvest_days!)
        planting.crop.update_lifespan_medians
        planting.crop.update_harvest_medians
      end

      it { expect(crop.median_days_to_first_harvest).to eq(20) }
      describe 'sets median time to harvest' do
        let(:planting) { FactoryBot.create :planting, crop: crop, planted_at: Time.zone.today }

        it { expect(planting.first_harvest_predicted_at).to eq(Time.zone.today + 20.days) }
      end

      describe 'harvest still growing' do
        let(:planting) { FactoryBot.create :planting, crop: crop, planted_at: Time.zone.today }

        it { expect(planting.before_harvest_time?).to eq true }
        it { expect(planting.harvest_time?).to eq false }
      end

      describe 'harvesting ready now' do
        let(:planting) { FactoryBot.create :planting, crop: crop, planted_at: 21.days.ago }

        it { expect(planting.first_harvest_predicted_at).to eq(1.day.ago.to_date) }
        it { expect(planting.before_harvest_time?).to eq false }
        it { expect(planting.harvest_time?).to eq true }
      end
    end

    describe 'planting has no harvests' do
      let(:planting) { FactoryBot.create :planting }

      before do
        planting.update_harvest_days!
        planting.crop.update_harvest_medians
      end

      it { expect(planting.days_to_first_harvest).to eq(nil) }
      it { expect(planting.days_to_last_harvest).to eq(nil) }
    end

    describe 'planting has first harvest' do
      let(:planting) { FactoryBot.create :planting, planted_at: 100.days.ago }

      before do
        FactoryBot.create(:harvest,
                          planting:     planting,
                          crop:         planting.crop,
                          harvested_at: 10.days.ago)
        planting.update_harvest_days!
        planting.crop.update_harvest_medians
      end

      it { expect(planting.days_to_first_harvest).to eq(90) }
      it { expect(planting.days_to_last_harvest).to eq(nil) }
      it { expect(planting.crop.median_days_to_first_harvest).to eq(90) }
      it { expect(planting.crop.median_days_to_last_harvest).to eq(nil) }
    end

    describe 'planting has last harvest' do
      let(:planting) { FactoryBot.create :planting, planted_at: 100.days.ago, finished_at: 1.day.ago, finished: true }

      before do
        FactoryBot.create :harvest, planting: planting, crop: planting.crop, harvested_at: 90.days.ago
        FactoryBot.create :harvest, planting: planting, crop: planting.crop, harvested_at: 10.days.ago
        planting.update_harvest_days!
        planting.crop.update_harvest_medians
      end

      it { expect(planting.days_to_first_harvest).to eq(10) }
      it { expect(planting.days_to_last_harvest).to eq(90) }
      it { expect(planting.crop.median_days_to_first_harvest).to eq(10) }
      it { expect(planting.crop.median_days_to_last_harvest).to eq(90) }
    end
  end

  describe 'planting perennial' do
    let(:crop) { FactoryBot.create(:crop, name: 'feijoa', perennial: true) }
    it { expect(planting.perennial?).to eq true }
    describe 'no harvest to predict from' do
      it { expect(planting.harvest_months).to eq({}) }
    end

    describe 'harvests used to predict' do
      before do
        FactoryBot.create :harvest, planting: planting, crop: crop, harvested_at: '1 May 2019'
        FactoryBot.create :harvest, planting: planting, crop: crop, harvested_at: '18 June 2019'
        FactoryBot.create_list :harvest, 4, planting: planting, crop: crop, harvested_at: '18 August 2019'
      end
      it { expect(planting.harvest_months).to eq(5 => 1, 6 => 1, 8 => 4) }
    end

    describe 'nearby plantings used to predict' do
      # Note the locations used need to be stubbed in geocoder
      let(:garden) { FactoryBot.create :garden, location: 'Edinburgh', owner: garden_owner }

      before do
        # Near by planting with harvests
        nearby_garden = FactoryBot.create :garden, location: 'Greenwich, UK'
        nearby_planting = FactoryBot.create(:planting,
                                            crop:       crop,
                                            garden:     nearby_garden,
                                            owner:      nearby_garden.owner,
                                            planted_at: '1 January 2000')
        FactoryBot.create :harvest, planting: nearby_planting, crop: crop,
                                    harvested_at: '1 May 2019'
        FactoryBot.create :harvest, planting: nearby_planting, crop: crop,
                                    harvested_at: '18 June 2019'
        FactoryBot.create_list :harvest, 4, planting: nearby_planting, crop: crop,
                                            harvested_at: '18 August 2008'

        # far away planting harvests
        faraway_garden = FactoryBot.create :garden, location: 'Amundsen-Scott Base, Antarctica'
        faraway_planting = FactoryBot.create :planting, garden: faraway_garden, crop: crop,
                                                        owner: faraway_garden.owner, planted_at: '16 May 2001'

        FactoryBot.create_list :harvest, 4, planting: faraway_planting, crop: crop,
                                            harvested_at: '18 December 2006'
      end
      it { expect(planting.harvest_months).to eq(5 => 1, 6 => 1, 8 => 4) }
    end
  end
  it 'has an owner' do
    planting.owner.should be_an_instance_of Member
  end

  it "generates a location" do
    planting.location.should eq garden.location
  end

  it "has a slug" do
    planting.slug.should match(/^hatupatu-springfield-community-garden-tomato$/)
  end

  it 'sorts in reverse creation order' do
    @planting2 = FactoryBot.create(:planting)
    described_class.first.should eq @planting2
  end

  describe '#planted?' do
    it "is false for future plantings" do
      planting = FactoryBot.create :planting, planted_at: Time.zone.today + 1
      expect(planting.planted?).to eq(false)
    end
    it "is false for never planted" do
      planting = FactoryBot.create :planting, planted_at: nil
      expect(planting.planted?).to eq(false)
    end
    it "is true for past plantings" do
      planting = FactoryBot.create :planting, planted_at: Time.zone.today - 1
      expect(planting.planted?).to eq(true)
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

    it 'has a sunniness value' do
      planting.sunniness.should eq 'sun'
    end

    it 'all three valid sunniness values should work' do
      ['sun', 'shade', 'semi-shade', nil, ''].each do |s|
        @planting = FactoryBot.build(:planting, sunniness: s)
        @planting.should be_valid
      end
    end

    it 'refuses invalid sunniness values' do
      @planting = FactoryBot.build(:planting, sunniness: 'not valid')
      @planting.should_not be_valid
      @planting.errors[:sunniness].should include("not valid is not a valid sunniness value")
    end
  end

  context 'planted from' do
    it 'has a planted_from value' do
      @planting = FactoryBot.create(:seed_planting)
      @planting.planted_from.should eq 'seed'
    end

    it 'all valid planted_from values should work' do
      [
        'seed', 'seedling', 'cutting', 'root division',
        'runner', 'bare root plant', 'advanced plant',
        'graft', 'layering', 'bulb', 'root/tuber', nil, ''
      ].each do |p|
        @planting = FactoryBot.build(:planting, planted_from: p)
        @planting.should be_valid
      end
    end

    it 'refuses invalid planted_from values' do
      @planting = FactoryBot.build(:planting, planted_from: 'not valid')
      @planting.should_not be_valid
      @planting.errors[:planted_from].should include("not valid is not a valid planting method")
    end
  end

  # we decided that all the tests for the planting/photo association would
  # be done on this side, not on the photos side
  context 'photos' do
    let(:planting) { FactoryBot.create(:planting) }
    let(:photo) { FactoryBot.create(:photo, owner_id: planting.owner_id) }

    before { planting.photos << photo }

    it 'has a photo' do
      expect(planting.photos.first).to eq photo
    end

    it 'is found in has_photos scope' do
      expect(described_class.has_photos).to include(planting)
    end

    it 'deletes association with photos when photo is deleted' do
      photo.destroy
      planting.reload
      expect(planting.photos).to be_empty
    end

    it 'has a default photo' do
      expect(planting.default_photo).to eq photo
    end

    it 'chooses the most recent photo' do
      @photo2 = FactoryBot.create(:photo, owner: planting.owner)
      planting.photos << @photo2
      expect(planting.default_photo).to eq @photo2
    end
  end

  context 'interesting plantings' do
    describe 'picks up interesting plantings' do
      before do
        # plantings have members created implicitly for them
        # each member is different, hence these are all interesting
        @planting1 = FactoryBot.create(:planting, :with_photo, planted_at: 5.days.ago)
        @planting2 = FactoryBot.create(:planting, :with_photo, planted_at: 4.days.ago)
        @planting3 = FactoryBot.create(:planting, :with_photo, planted_at: 3.days.ago)
        @planting4 = FactoryBot.create(:planting, :with_photo, planted_at: 2.days.ago)
      end

      it { expect(described_class.interesting).to eq([@planting4, @planting3, @planting2, @planting1]) }
    end

    context "default arguments" do
      it 'ignores plantings without photos' do
        # first, an interesting planting
        @planting = FactoryBot.create(:planting)
        @planting.photos << FactoryBot.create(:photo, owner: @planting.owner)
        @planting.save

        # this one doesn't have a photo
        @no_photo_planting = FactoryBot.create(:planting)

        expect(described_class.interesting).to include @planting
        expect(described_class.interesting).not_to include @no_photo_planting
      end

      it 'ignores plantings with the same owner' do
        # this planting is older
        @planting1 = FactoryBot.create(:planting, created_at: 1.day.ago)
        @planting1.photos << FactoryBot.create(:photo, owner_id: @planting1.owner_id)
        @planting1.save

        # this one is newer, and has the same owner, through the garden
        @planting2 = FactoryBot.create(:planting,
                                       created_at: 1.minute.ago,
                                       garden:     @planting1.garden,
                                       owner:      @planting1.owner)
        @planting2.photos << FactoryBot.create(:photo, owner: @planting2.owner)
        @planting2.save

        # result: the newer one is interesting, the older one isn't
        expect(described_class.interesting).to include @planting2
        expect(described_class.interesting).not_to include @planting1
      end
    end

    context "with howmany argument" do
      it "only returns the number asked for" do
        @plantings = FactoryBot.create_list(:planting, 10)
        @plantings.each do |p|
          p.photos << FactoryBot.create(:photo, owner: p.owner)
        end
        expect(described_class.interesting.limit(3).count).to eq 3
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
      described_class.finished.should include @f
      described_class.finished.should_not include @p
    end

    it 'has current scope' do
      @p = FactoryBot.create(:planting)
      @f = FactoryBot.create(:finished_planting)
      described_class.current.should include @p
      described_class.current.should_not include @f
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
    expect(described_class.joins(:owner).all).to include(planting)
    planting.owner.destroy
    expect(described_class.joins(:owner).all).not_to include(planting)
  end

  context 'ancestry' do
    let(:parent_seed) { FactoryBot.create :seed }
    let(:planting) { FactoryBot.create :planting, parent_seed: parent_seed }

    it "planting has a parent seed" do
      expect(planting.parent_seed).to eq(parent_seed)
    end
    it "seed has a child planting" do
      expect(parent_seed.child_plantings).to eq [planting]
    end
    describe 'grandchildren' do
      let(:grandchild_seed) { FactoryBot.create :seed, parent_planting: planting }

      it { expect(grandchild_seed.parent_planting).to eq planting }
      it { expect(grandchild_seed.parent_planting.parent_seed).to eq parent_seed }
    end
  end

  describe 'active scope' do
    let(:member) { FactoryBot.create :member }
    let!(:planting) do
      FactoryBot.create :planting, owner: member, garden: member.gardens.first
    end
    let!(:finished_planting) do
      FactoryBot.create :finished_planting, owner: member, garden: member.gardens.first
    end
    it { expect(member.plantings.active).to include(planting) }
    it { expect(member.plantings.active).not_to include(finished_planting) }
  end

  describe 'homepage', :search do
    let!(:interesting_planting) { FactoryBot.create :planting, :reindex, :with_photo }
    let!(:finished_interesting_planting) { FactoryBot.create :finished_planting, :reindex, :with_photo }
    let!(:planting) { FactoryBot.create :planting, :reindex }

    before { described_class.reindex }
    subject { described_class.homepage_records(100) }

    it { expect(subject.count).to eq 2 }
    it { expect(subject.map(&:id)).to eq([interesting_planting.id.to_s, finished_interesting_planting.id.to_s]) }
  end
end
