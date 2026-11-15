# frozen_string_literal: true

require 'rails_helper'

describe SeasonalCrops do
  subject(:result) { described_class.new(climate).sown_in(months) }

  # Spring, September to November, with days reaching 12, 15 and 18 °C, averages 4 °C cooler and coldest nights 8 °C cooler, then a
  # 25 °C summer.
  let(:highs) { { 9 => 12.0, 10 => 15.0, 11 => 18.0, 12 => 25.0, 1 => 25.0 } }
  let(:climate) do
    instance_double(SeasonalClimate, monthly_means: highs.transform_values { |v| v - 4 }, monthly_nights: highs.transform_values do |v|
      v - 8
    end,
                                     monthly_days: highs)
  end
  let(:months) { [9, 10, 11] }
  let!(:suitable) { crop_with(10, 20, gmin: 90, tmin: 0, tmax: 40) }

  # A crop whose record has the options, and the crop's own attributes among them kept for the crop.
  def crop_with(topmn, topmx, **options)
    crop_attributes, record = options.partition { |key, _| %i(approval_status plantings_count).include?(key) }.map(&:to_h)
    create(:crop, ecocrop_record: create(:ecocrop_data, { gmin: 60, tmin: 0, tmax: 40, **record, topmn:, topmx: }), **crop_attributes)
  end

  def optimal
    result[:optimal]
  end

  def tolerable
    result[:tolerable]
  end

  describe 'optimal' do
    it 'includes a crop whose best range holds for its cycle' do
      expect(optimal).to include suitable
    end

    it 'leaves out a crop whose cycle is on average hotter than its best range' do
      slow = crop_with(10, 16, gmin: 150)
      expect(optimal).not_to include slow
    end

    it 'includes a crop that is out of its best range for some months of the cycle' do
      uneven = crop_with(14, 20, gmin: 90)
      expect(optimal).to include uneven
    end

    it 'counts a crop that is in range from a later start month' do
      later = crop_with(14, 20, gmin: 60)
      expect(optimal).to include later
    end

    it 'leaves out a crop whose best range is warmer' do
      warm = crop_with(22, 30)
      expect(optimal).not_to include warm
    end

    it 'leaves out a crop the average temperature is too cool for, whatever its best range' do
      tender = crop_with(10, 20, gmin: 90, tmin: 20)
      expect(optimal).not_to include tender
    end

    it 'includes a crop whose lowest growing temperature the coldest nights fall below' do
      hardy = crop_with(10, 20, gmin: 90, tmin: 6)
      expect(optimal).to include hardy
    end

    it 'leaves out a crop whose killing temperature the nights reach' do
      frost_tender = crop_with(12, 30, gmin: 90, ktmp: 12)
      expect(optimal).not_to include frost_tender
    end

    it 'includes a crop whose killing temperature the nights stay above' do
      hardy = crop_with(12, 30, gmin: 90, ktmp: 5)
      expect(optimal).to include hardy
    end

    it 'leaves out a crop the days would kill' do
      heat_shy = crop_with(10, 20, gmin: 90, tmax: 14)
      expect(optimal).not_to include heat_shy
    end

    it 'includes a crop with no top temperature it survives' do
      hardy = crop_with(10, 20, gmin: 90, tmax: nil)
      expect(optimal).to include hardy
    end

    it 'leaves out a crop with no cycle length' do
      unknown = crop_with(10, 20, gmin: nil)
      expect(optimal).not_to include unknown
    end

    it 'leaves out a crop with a cycle of zero days' do
      zero = crop_with(10, 20, gmin: 0)
      expect(optimal).not_to include zero
    end

    it 'falls back to the median days when EcoCrop gives no cycle' do
      median = crop_with(10, 20, gmin: nil)
      median.update!(median_days_to_first_harvest: 90)
      expect(optimal).to include median
    end

    it 'goes by the degree days of the crop before its EcoCrop cycle' do
      slow_cycle = crop_with(10, 20, gmin: 400)
      slow_cycle.update!(growing_degree_days: 600)
      expect(optimal).to include slow_cycle
    end

    it 'leaves out a crop with no record' do
      bare = create(:crop)
      expect(optimal).not_to include bare
    end

    it 'uses the parent crop record for a crop with none of its own' do
      child = create(:crop, parent: suitable)
      expect(optimal).to include child
    end

    it 'leaves out a crop that is not approved' do
      pending_crop = crop_with(10, 20, gmin: 90, approval_status: 'pending')
      expect(optimal).not_to include pending_crop
    end

    it 'puts the most planted first' do
      popular = crop_with(10, 20, gmin: 90, plantings_count: 50)
      expect(optimal.first).to eq popular
    end

    it 'leaves out the crops it is told to' do
      expect(described_class.new(climate).sown_in(months, except: [suitable.id])[:optimal]).not_to include suitable
    end

    it 'stops at the limit' do
      crop_with(10, 20, gmin: 90)
      expect(described_class.new(climate).sown_in(months, limit: 1)[:optimal].size).to eq 1
    end
  end

  describe 'tolerable' do
    it 'includes a crop that survives but whose best range is cooler' do
      cool = crop_with(2, 10, gmin: 60)
      expect(tolerable).to include cool
    end

    it 'leaves out a crop already in the optimal list' do
      expect(tolerable).not_to include suitable
    end

    it 'leaves out a crop the nights would kill' do
      tender = crop_with(2, 10, gmin: 60, tmin: 12)
      expect(tolerable).not_to include tender
    end

    it 'leaves out a crop whose killing temperature the nights reach' do
      frost_tender = crop_with(2, 10, gmin: 60, ktmp: 12)
      expect(tolerable).not_to include frost_tender
    end

    it 'ignores a longest cycle of zero days' do
      zero = crop_with(2, 10, gmin: 60, gmax: 0)
      expect(tolerable).to include zero
    end

    it 'uses the longest cycle' do
      slow = crop_with(2, 10, gmin: 60, gmax: 400)
      expect(tolerable).not_to include slow
    end
  end

  describe '.for' do
    let(:spring) { SeasonalClimate::Season.new(name: :spring, months:, mean: 15, night: nil, night_usual: nil, day: nil, day_usual: nil, rain: nil, current: false) }

    before { allow(climate).to receive(:seasons).and_return([spring]) }

    it 'gives the crops of each season with an average' do
      expect(described_class.for(climate)).to eq(spring: { optimal: [suitable], tolerable: [] })
    end
  end
end
