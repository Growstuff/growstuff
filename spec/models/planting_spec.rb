# frozen_string_literal: true

require 'rails_helper'

describe Planting do
  let(:crop)         { create(:tomato)                                                            }
  let(:garden_owner) { create(:member, login_name: 'hatupatu')                                    }
  let(:garden)       { create(:garden, owner: garden_owner, name: 'Springfield Community Garden') }
  let(:planting)     { create(:planting, crop:, garden:, owner: garden.owner) }

  describe 'planting lifespan predictions' do
    context 'no predications data yet' do
      describe 'planting planted, not finished' do
        let(:planting) { create(:planting, planted_at: 30.days.ago, finished_at: nil, finished: false) }

        it { expect(planting.crop.median_lifespan).to be_nil }
        it { expect(planting.expected_lifespan).to be_nil }
        it { expect(planting.age_in_days).to eq(30) }
        it { expect(planting.percentage_grown).to be_nil }
      end

      describe 'planting not planted yet' do
        let(:planting) { create(:planting, planted_at: nil, finished_at: nil, finished: false) }

        it { expect(planting.crop.median_lifespan).to be_nil }
        it { expect(planting.expected_lifespan).to be_nil }
        it { expect(planting.age_in_days).to be_nil }
        it { expect(planting.percentage_grown).to eq(0) }
      end

      describe 'planting finished, no planted_at' do
        let(:planting) { create(:planting, planted_at: nil, finished_at: 1.day.ago, finished: true) }

        it { expect(planting.crop.median_lifespan).to be_nil }
        it { expect(planting.expected_lifespan).to be_nil }
        it { expect(planting.age_in_days).to be_nil }
        it { expect(planting.percentage_grown).to eq(100) }
      end

      describe 'planting all finished' do
        let(:planting) { create(:planting, planted_at: 30.days.ago, finished_at: 10.days.ago, finished: true) }

        it { expect(planting.crop.median_lifespan).to be_nil }
        it { expect(planting.expected_lifespan).to eq(20) }
        it { expect(planting.age_in_days).to eq(20) }
        it { expect(planting.percentage_grown).to eq(100) }
      end

      describe 'planting finishing in the future' do
        let(:planting) { create(:planting, planted_at: 30.days.ago, finished_at: 10.days.from_now, finished: false) }

        it { expect(planting.expected_lifespan).to eq(40) }
        it { expect(planting.age_in_days).to eq(30) }
        it { expect(planting.percentage_grown).to eq(75) }
      end
    end

    context 'lots of data' do
      before do
        create(:planting, crop: planting.crop, planted_at: 10.days.ago)
        create(:planting, crop: planting.crop, planted_at: 100.days.ago, finished_at: 50.days.ago)
        create(:planting, crop: planting.crop, planted_at: 100.days.ago, finished_at: 51.days.ago)
        create(:planting, crop: planting.crop, planted_at: 2.years.ago, finished_at: 50.days.ago)
        create(:planting, crop: planting.crop, planted_at: 150.days.ago, finished_at: 100.days.ago)
        planting.crop.update_lifespan_medians
      end

      it { expect(planting.crop.median_lifespan).to eq 50 }

      describe 'planting 30 days ago, not finished' do
        let(:planting) { create(:planting, planted_at: 30.days.ago) }

        # 30 / 50 = 60%
        it { expect(planting.percentage_grown).to eq 60.0 }
        # planted 30 days ago
        it { expect(planting.age_in_days).to eq 30 }
        # means 20 days to go
        it { expect(planting.finish_predicted_at).to eq Time.zone.today + 20.days }
      end

      describe 'child crop uses parent data' do
        let(:child_crop)     { create(:crop, parent: crop, name: 'child')                   }
        let(:child_planting) { create(:planting, crop: child_crop, planted_at: 30.days.ago) }

        # not data for this crop
        it { expect(child_crop.median_lifespan).to be_nil }
        # 30 / 50 = 60%
        it { expect(child_planting.percentage_grown).to eq 60.0 }
        # planted 30 days ago
        it { expect(child_planting.age_in_days).to eq 30 }
        # means 20 days to go
        it { expect(child_planting.finish_predicted_at).to eq Time.zone.today + 20.days }
      end

      describe 'planting not planted yet' do
        let(:planting) { create(:planting, planted_at: nil, finished_at: nil) }

        it { expect(planting.percentage_grown).to eq 0 }
      end

      describe 'planting finished 10 days, but was never planted' do
        let(:planting) { create(:planting, planted_at: nil, finished_at: 10.days.ago) }

        it { expect(planting.percentage_grown).to eq 100 }
      end

      describe 'planted 30 days ago, finished 10 days ago' do
        let(:planting) { create(:planting, planted_at: 30.days.ago, finished_at: 10.days.ago) }

        it { expect(planting.age_in_days).to eq 20 }
        it { expect(planting.percentage_grown).to eq 100 }
      end
    end
  end

  describe 'planting first harvest preductions' do
    context 'no data' do
      let(:planting) { create(:planting) }

      it { expect(planting.crop.median_days_to_first_harvest).to be_nil }
      it { expect(planting.crop.median_days_to_last_harvest).to be_nil }
      it { expect(planting.days_to_first_harvest).to be_nil }
      it { expect(planting.days_to_last_harvest).to be_nil }
      it { expect(planting.expected_lifespan).to be_nil }
    end

    context 'lots of data' do
      let(:crop) { create(:crop) }
      # this is a method so it creates a new one each time

      def one_hundred_day_old_planting
        create(:planting, crop:, planted_at: 100.days.ago)
      end
      before do
        # 50 days to harvest
        create(:harvest, harvested_at: 50.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)
        # 20 days to harvest
        create(:harvest, harvested_at: 80.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)
        # 10 days to harvest
        create(:harvest, harvested_at: 90.days.ago, crop: planting.crop,
                                    planting: one_hundred_day_old_planting)

        planting.crop.plantings.each(&:update_harvest_days!)
        planting.crop.update_lifespan_medians
        planting.crop.update_harvest_medians
      end

      it { expect(crop.median_days_to_first_harvest).to eq(20) }

      describe 'sets median time to harvest' do
        let(:planting) { create(:planting, crop:, planted_at: Time.zone.today) }

        it { expect(planting.first_harvest_predicted_at).to eq(Time.zone.today + 20.days) }
      end

      describe 'harvest still growing' do
        let(:planting) { create(:planting, crop:, planted_at: Time.zone.today) }

        it { expect(planting.before_harvest_time?).to be true }
        it { expect(planting.harvest_time?).to be false }
      end

      describe 'harvesting ready now' do
        let(:planting) { create(:planting, crop:, planted_at: 21.days.ago) }

        it { expect(planting.first_harvest_predicted_at).to eq(1.day.ago.to_date) }
        it { expect(planting.before_harvest_time?).to be false }
        it { expect(planting.harvest_time?).to be true }
      end
    end

    describe 'planting has no harvests' do
      let(:planting) { create(:planting) }

      before do
        planting.update_harvest_days!
        planting.crop.update_harvest_medians
      end

      it { expect(planting.days_to_first_harvest).to be_nil }
      it { expect(planting.days_to_last_harvest).to be_nil }
    end

    describe 'planting has first harvest' do
      let(:planting) { create(:planting, planted_at: 100.days.ago) }

      before do
        create(:harvest,
               planting:,
               crop:         planting.crop,
               harvested_at: 10.days.ago)
        planting.update_harvest_days!
        planting.crop.update_harvest_medians
      end

      it { expect(planting.days_to_first_harvest).to eq(90) }
      it { expect(planting.days_to_last_harvest).to be_nil }
      it { expect(planting.crop.median_days_to_first_harvest).to eq(90) }
      it { expect(planting.crop.median_days_to_last_harvest).to be_nil }
    end

    describe 'planting has last harvest' do
      let(:planting) { create(:planting, planted_at: 100.days.ago, finished_at: 1.day.ago, finished: true) }

      before do
        create(:harvest, planting:, crop: planting.crop, harvested_at: 90.days.ago)
        create(:harvest, planting:, crop: planting.crop, harvested_at: 10.days.ago)
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
    let(:crop) { create(:crop, name: 'feijoa', perennial: true) }

    it { expect(planting.perennial?).to be true }

    describe 'no harvest to predict from' do
      it { expect(planting.harvest_months).to eq({}) }
    end

    describe 'harvests used to predict' do
      before do
        create(:harvest, planting:, crop:, harvested_at: '1 May 2019')
        create(:harvest, planting:, crop:, harvested_at: '18 June 2019')
        create_list(:harvest, 4, planting:, crop:, harvested_at: '18 August 2019')
      end

      it { expect(planting.harvest_months).to eq(5 => 1, 6 => 1, 8 => 4) }
    end

    describe 'nearby plantings used to predict' do
      # Note the locations used need to be stubbed in geocoder
      let(:garden) { create(:garden, location: 'Edinburgh', owner: garden_owner) }

      before do
        # Near by planting with harvests
        nearby_garden = create(:garden, location: 'Greenwich, UK')
        nearby_planting = create(:planting,
                                 crop:,
                                 garden:     nearby_garden,
                                 owner:      nearby_garden.owner,
                                 planted_at: '1 January 2000')
        create(:harvest, planting: nearby_planting, crop:,
                                    harvested_at: '1 May 2019')
        create(:harvest, planting: nearby_planting, crop:,
                                    harvested_at: '18 June 2019')
        create_list(:harvest, 4, planting: nearby_planting, crop:,
                                            harvested_at: '18 August 2008')

        # far away planting harvests
        faraway_garden = create(:garden, location: 'Amundsen-Scott Base, Antarctica')
        faraway_planting = create(:planting, garden: faraway_garden, crop:,
                                                        owner: faraway_garden.owner, planted_at: '16 May 2001')

        create_list(:harvest, 4, planting: faraway_planting, crop:,
                                            harvested_at: '18 December 2006')
      end

      it { expect(planting.harvest_months).to eq(5 => 1, 6 => 1, 8 => 4) }
    end
  end

  it 'has an owner' do
    expect(planting.owner).to be_an_instance_of Member
  end

  it "generates a location" do
    expect(planting.location).to eq garden.location
  end

  it "has a slug" do
    expect(planting.slug).to match(/^hatupatu-springfield-community-garden-tomato$/)
  end

  it 'sorts in reverse creation order' do
    @planting2 = create(:planting)
    expect(described_class.first).to eq @planting2
  end

  describe '#planted?' do
    it "is false for future plantings" do
      planting = create(:planting, planted_at: Time.zone.today + 1)
      expect(planting.planted?).to be(false)
    end

    it "is false for never planted" do
      planting = create(:planting, planted_at: nil)
      expect(planting.planted?).to be(false)
    end

    it "is true for past plantings" do
      planting = create(:planting, planted_at: Time.zone.today - 1)
      expect(planting.planted?).to be(true)
    end
  end

  context 'delegation' do
    it 'system name' do
      expect(planting.crop_name).to eq planting.crop.name
    end

    it 'wikipedia url' do
      expect(planting.crop_en_wikipedia_url).to eq planting.crop.en_wikipedia_url
    end

    it 'default scientific name' do
      expect(planting.crop_default_scientific_name).to eq planting.crop.default_scientific_name
    end

    it 'plantings count' do
      expect(planting.crop_plantings_count).to eq planting.crop.plantings_count
    end
  end

  context 'quantity' do
    it 'allows integer quantities' do
      @planting = build(:planting, quantity: 99)
      expect(@planting).to be_valid
    end

    it "doesn't allow decimal quantities" do
      @planting = build(:planting, quantity: 99.9)
      expect(@planting).not_to be_valid
    end

    it "doesn't allow non-numeric quantities" do
      @planting = build(:planting, quantity: 'foo')
      expect(@planting).not_to be_valid
    end

    it "allows blank quantities" do
      @planting = build(:planting, quantity: nil)
      expect(@planting).to be_valid
      @planting = build(:planting, quantity: '')
      expect(@planting).to be_valid
    end
  end

  context 'sunniness' do
    let(:planting) { create(:sunny_planting) }

    it 'has a sunniness value' do
      expect(planting.sunniness).to eq 'sun'
    end

    it 'all three valid sunniness values should work' do
      ['sun', 'shade', 'semi-shade', nil, ''].each do |s|
        @planting = build(:planting, sunniness: s)
        expect(@planting).to be_valid
      end
    end

    it 'refuses invalid sunniness values' do
      @planting = build(:planting, sunniness: 'not valid')
      expect(@planting).not_to be_valid
      expect(@planting.errors[:sunniness]).to include("not valid is not a valid sunniness value")
    end
  end

  context 'planted from' do
    it 'has a planted_from value' do
      @planting = create(:seed_planting)
      expect(@planting.planted_from).to eq 'seed'
    end

    it 'all valid planted_from values should work' do
      [
        'seed', 'seedling', 'cutting', 'root division',
        'runner', 'bare root plant', 'advanced plant',
        'graft', 'layering', 'bulb', 'root/tuber', nil, ''
      ].each do |p|
        @planting = build(:planting, planted_from: p)
        expect(@planting).to be_valid
      end
    end

    it 'refuses invalid planted_from values' do
      @planting = build(:planting, planted_from: 'not valid')
      expect(@planting).not_to be_valid
      expect(@planting.errors[:planted_from]).to include("not valid is not a valid planting method")
    end
  end

  # we decided that all the tests for the planting/photo association would
  # be done on this side, not on the photos side
  context 'photos' do
    let(:planting) { create(:planting) }
    let(:photo) { create(:photo, owner_id: planting.owner_id) }

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
      @photo2 = create(:photo, owner: planting.owner)
      planting.photos << @photo2
      expect(planting.default_photo).to eq @photo2
    end
  end

  context 'interesting plantings' do
    describe 'picks up interesting plantings' do
      before do
        # plantings have members created implicitly for them
        # each member is different, hence these are all interesting
        @planting1 = create(:planting, :with_photo, planted_at: 5.days.ago)
        @planting2 = create(:planting, :with_photo, planted_at: 4.days.ago)
        @planting3 = create(:planting, :with_photo, planted_at: 3.days.ago)
        @planting4 = create(:planting, :with_photo, planted_at: 2.days.ago)
      end

      it { expect(described_class.interesting).to eq([@planting4, @planting3, @planting2, @planting1]) }
    end

    context "default arguments" do
      it 'ignores plantings without photos' do
        # first, an interesting planting
        @planting = create(:planting)
        @planting.photos << create(:photo, owner: @planting.owner)
        @planting.save

        # this one doesn't have a photo
        @no_photo_planting = create(:planting)

        expect(described_class.interesting).to include @planting
        expect(described_class.interesting).not_to include @no_photo_planting
      end

      it 'ignores plantings with the same owner' do
        # this planting is older
        @planting1 = create(:planting, created_at: 1.day.ago)
        @planting1.photos << create(:photo, owner_id: @planting1.owner_id)
        @planting1.save

        # this one is newer, and has the same owner, through the garden
        @planting2 = create(:planting,
                            created_at: 1.minute.ago,
                            garden:     @planting1.garden,
                            owner:      @planting1.owner)
        @planting2.photos << create(:photo, owner: @planting2.owner)
        @planting2.save

        # result: the newer one is interesting, the older one isn't
        expect(described_class.interesting).to include @planting2
        expect(described_class.interesting).not_to include @planting1
      end
    end

    context "with howmany argument" do
      it "only returns the number asked for" do
        @plantings = create_list(:planting, 10)
        @plantings.each do |p|
          p.photos << create(:photo, owner: p.owner)
        end
        expect(described_class.interesting.limit(3).count).to eq 3
      end
    end
  end # interesting plantings

  context "finished" do
    it 'has finished fields' do
      @planting = create(:finished_planting)
      expect(@planting.finished).to be true
      expect(@planting.finished_at).to be_an_instance_of Date
    end

    it 'has finished scope' do
      @p = create(:planting)
      @f = create(:finished_planting)
      expect(described_class.finished).to include @f
      expect(described_class.finished).not_to include @p
    end

    it 'has current scope' do
      @p = create(:planting)
      @f = create(:finished_planting)
      expect(described_class.current).to include @p
      expect(described_class.current).not_to include @f
    end

    context "finished date validation" do
      it 'requires finished date after planting date' do
        @f = build(:finished_planting, planted_at: '2014-01-01', finished_at: '2013-01-01')
        expect(@f).not_to be_valid
      end

      it 'allows just the planted date' do
        @f = build(:planting, planted_at: '2013-01-01', finished_at: nil)
        expect(@f).to be_valid
      end

      it 'allows just the finished date' do
        @f = build(:planting, finished_at: '2013-01-01', planted_at: nil)
        expect(@f).to be_valid
      end
    end
  end

  context "failed" do
    let(:failed_planting) { create(:planting, failed: true) }

    it 'has a failed field' do
      expect(failed_planting.failed).to be true
    end

    it 'has a failed scope' do
      @p = create(:planting)
      @f = create(:planting, failed: true)
      expect(described_class.failed).to include @f
      expect(described_class.failed).not_to include @p
    end

    it 'is not included in the active scope' do
      @p = create(:planting)
      @f = create(:planting, failed: true)
      expect(described_class.active).to include @p
      expect(described_class.active).not_to include @f
    end

    it 'cannot be finished and failed' do
      @f = build(:planting, finished: true, failed: true)
      expect(@f).not_to be_valid
    end

    it 'is not finished' do
      @f = build(:planting, finished: true, failed: true)
      expect(@f.finished?).to be false
    end
  end

  it 'excludes deleted members' do
    expect(described_class.joins(:owner).all).to include(planting)
    planting.owner.destroy
    expect(described_class.joins(:owner).all).not_to include(planting)
  end

  context 'ancestry' do
    let(:parent_seed) { create(:seed) }
    let(:planting) { create(:planting, parent_seed:) }

    it "planting has a parent seed" do
      expect(planting.parent_seed).to eq(parent_seed)
    end

    it "seed has a child planting" do
      expect(parent_seed.child_plantings).to eq [planting]
    end

    describe 'grandchildren' do
      let(:grandchild_seed) { create(:seed, parent_planting: planting) }

      it { expect(grandchild_seed.parent_planting).to eq planting }
      it { expect(grandchild_seed.parent_planting.parent_seed).to eq parent_seed }
    end
  end

  describe 'active scope' do
    let(:member) { create(:member) }
    let!(:planting) do
      create(:planting, owner: member, garden: member.gardens.first)
    end
    let!(:finished_planting) do
      create(:finished_planting, owner: member, garden: member.gardens.first)
    end
    let!(:failed_planting) do
      create(:planting, failed: true, owner: member, garden: member.gardens.first)
    end

    it { expect(member.plantings.active).to include(planting) }
    it { expect(member.plantings.active).not_to include(finished_planting) }
    it { expect(member.plantings.active).not_to include(failed_planting) }
  end

  describe 'homepage', :search do
    subject { described_class.homepage_records(100) }

    let!(:interesting_planting) { create(:planting, :reindex, :with_photo) }
    let!(:finished_interesting_planting) { create(:finished_planting, :reindex, :with_photo) }
    let!(:planting) { create(:planting, :reindex) }

    before { described_class.reindex }

    it { expect(subject.count).to eq 3 }
    it { expect(subject.map(&:id)).to eq([interesting_planting.id.to_s, finished_interesting_planting.id.to_s, planting.id.to_s]) }
  end
end
