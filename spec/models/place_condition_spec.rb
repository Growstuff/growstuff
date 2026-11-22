# frozen_string_literal: true

require 'rails_helper'

describe PlaceCondition do
  describe '.for_planting' do
    subject(:days) { described_class.for_planting(planting).pluck(:occurred_on) }

    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) do
      create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 1, 10), finished: true, finished_at: Date.new(2026, 2, 10))
    end

    before do
      [Date.new(2026, 1, 9), Date.new(2026, 1, 15), Date.new(2026, 2, 11)].each do |date|
        create(:place_condition, latitude: -41.25, longitude: 174.75, occurred_on: date)
      end
      create(:place_condition, latitude: -30.0, longitude: 150.0, occurred_on: Date.new(2026, 1, 20))
    end

    it 'is the place\'s days while the planting lived' do
      expect(days).to eq [Date.new(2026, 1, 15)]
    end

    context 'when the garden is somewhere safe from frost' do
      before { garden.update_columns(frost_safe: true) } # rubocop:disable Rails/SkipsModelValidations

      it { is_expected.to be_empty }
    end

    context 'when the garden has no place' do
      before { garden.update_columns(latitude: nil, longitude: nil) } # rubocop:disable Rails/SkipsModelValidations

      it { is_expected.to be_empty }
    end

    context 'when it began in the nursery' do
      before do
        nursery = create(:garden, owner: planting.owner).tap(&:make_nursery!)
        create(:planting_history, planting:, garden: nursery, started_on: Date.new(2026, 1, 10), ended_on: Date.new(2026, 1, 20))
        create(:place_condition, latitude: -41.25, longitude: 174.75, occurred_on: Date.new(2026, 1, 25))
      end

      it 'leaves out the days it was safe from frost' do
        expect(days).to eq [Date.new(2026, 1, 25)]
      end
    end
  end

  describe '.refresh' do
    subject(:refresh) { described_class.refresh(latitude, longitude) }

    let(:latitude) { -41.25 }
    let(:longitude) { 174.75 }
    let(:kept) { described_class.at(latitude, longitude).order(:kind, :occurred_on).pluck(:kind, :occurred_on, :value) }

    # `weather` overrides any column of the day's reading.
    def reading(date, **weather)
      defaults = { temp_min_c: 8.0, temp_max_c: 14.0, wind_gust_max_kmh: 20.0, rainfall_mm: 0.0, snowfall_cm: 0.0 }
      create(:weather_reading, latitude:, longitude:, date:, **defaults, **weather)
    end

    # Mild, dry days, for the weather held before the day under test.
    def hold_readings(from, to)
      now = Time.current
      rows = (from..to).map do |date|
        { latitude:, longitude:, date:, source: 'test', temp_min_c: 8.0, temp_max_c: 14.0, snowfall_cm: 0.0, created_at: now,
updated_at: now }
      end
      WeatherReading.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'keeps the nights at or below the frost danger temperature' do
      reading(Date.new(2026, 8, 20), temp_min_c: 2.0)
      reading(Date.new(2026, 8, 21), temp_min_c: 2.1)
      refresh
      expect(kept).to eq [['frost', Date.new(2026, 8, 20), 2.0]]
    end

    it 'keeps the days with gusts of 100 km/h or more, with where from and the temperatures' do
      reading(Date.new(2026, 8, 20), wind_gust_max_kmh: 100.0, wind_direction_degrees: 225.0)
      reading(Date.new(2026, 8, 21), wind_gust_max_kmh: 99.9)
      refresh
      expect(described_class.damaging_wind.pluck(:occurred_on, :value, :direction_degrees, :temp_min_c, :temp_max_c))
        .to eq [[Date.new(2026, 8, 20), 100.0, 225.0, 8.0, 14.0]]
    end

    it 'keeps the days with 100 mm of rain or more' do
      reading(Date.new(2026, 8, 20), rainfall_mm: 100.0)
      reading(Date.new(2026, 8, 21), rainfall_mm: 99.9)
      refresh
      expect(kept).to eq [['heavy_rain', Date.new(2026, 8, 20), 100.0]]
    end

    it 'keeps the days with a high over 40 °C' do
      reading(Date.new(2026, 8, 20), temp_max_c: 40.1)
      reading(Date.new(2026, 8, 21), temp_max_c: 40.0)
      refresh
      expect(kept).to eq [['extreme_heat', Date.new(2026, 8, 20), 40.1]]
    end

    it 'does not duplicate a day when run again' do
      reading(Date.new(2026, 8, 20), temp_min_c: -1.0)
      2.times { described_class.refresh(latitude, longitude) }
      expect(described_class.count).to eq 1
    end

    it 'leaves other places alone' do
      reading(Date.new(2026, 8, 20), temp_min_c: -1.0)
      create(:place_condition, latitude: -30.0, longitude: 150.0)
      refresh
      expect(described_class.at(-30.0, 150.0).count).to eq 1
    end

    context 'when a day kept earlier no longer counts' do
      before { create(:place_condition, latitude:, longitude:, kind: 'heavy_rain', occurred_on: Date.new(2026, 8, 25)) }

      it 'drops it' do
        refresh
        expect(described_class.heavy_rain).to be_empty
      end
    end

    context 'with snow when we hold the weather from the start of the winter' do
      before do
        hold_readings(Date.new(2026, 1, 1), Date.new(2026, 8, 24))
        reading(Date.new(2026, 8, 25), snowfall_cm: 3.0)
        reading(Date.new(2026, 8, 26), snowfall_cm: 5.0)
      end

      it 'keeps the first snowfall of the winter, in the southern hemisphere' do
        refresh
        expect(described_class.first_snow.pluck(:occurred_on, :value)).to eq [[Date.new(2026, 8, 25), 3.0]]
      end
    end

    context 'with snow in the northern hemisphere' do
      let(:latitude) { 51.25 }

      before do
        hold_readings(Date.new(2025, 7, 1), Date.new(2025, 12, 9))
        reading(Date.new(2025, 12, 10), snowfall_cm: 2.0)
      end

      it 'counts the winter from July' do
        refresh
        expect(described_class.first_snow.pluck(:occurred_on)).to eq [Date.new(2025, 12, 10)]
      end
    end

    context 'when we do not hold the weather from the start of the winter' do
      before do
        hold_readings(Date.new(2026, 7, 1), Date.new(2026, 8, 24))
        reading(Date.new(2026, 8, 25), snowfall_cm: 3.0)
      end

      it 'cannot say it is the first, so keeps nothing' do
        refresh
        expect(described_class.first_snow).to be_empty
      end
    end
  end
end
