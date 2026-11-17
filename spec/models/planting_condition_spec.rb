# frozen_string_literal: true

require 'rails_helper'

describe PlantingCondition do
  describe '.refresh' do
    subject(:refresh) { described_class.refresh(planting, today:) }

    let(:today) { Date.new(2026, 9, 20) }
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:crop) { create(:crop, ecocrop_record: create(:ecocrop_data, ktmp: -1, tmax: 30)) }
    let(:planting) { create(:planting, garden:, owner: garden.owner, crop:, planted_at: Date.new(2026, 8, 18)) }
    let(:cell) { planting.weather_cell }
    let(:kept) { planting.conditions.pluck(:kind, :occurred_on, :value, :threshold) }

    # `weather` overrides any column of the day's reading.
    def reading(date, low, high = 12.0, **weather)
      defaults = { temp_min_c: low, temp_max_c: high, wind_gust_max_kmh: 20.0, wind_direction_degrees: 270.0, rainfall_mm: 0.0,
snowfall_cm: 0.0 }
      create(:weather_reading, latitude: cell.first, longitude: cell.last, date:, **defaults, **weather)
    end

    # Mild, dry days with no snow, for the weather held before the planting.
    def hold_readings(from, to, except: [])
      now = Time.current
      rows = (from..to).excluding(except).map do |date|
        { latitude: cell.first, longitude: cell.last, date:, source: 'test', temp_min_c: 5.0, temp_max_c: 12.0, snowfall_cm: 0.0,
          rainfall_mm: 0.0, created_at: now, updated_at: now }
      end
      WeatherReading.insert_all(rows) # rubocop:disable Rails/SkipsModelValidations
    end

    before do
      create(:frost_stat, latitude: cell.first, longitude: cell.last, threshold_c: FrostCalculator::FROST_DANGER_C, status: 'frost',
                          first_frost_p10: 154, first_frost_median: 173, last_frost_median: 240, last_frost_p90: 274)
      reading(Date.new(2026, 8, 20), -1.5)
      reading(Date.new(2026, 8, 21), 6.0)
      reading(Date.new(2026, 8, 22), 1.0, 33.0)
      reading(Date.new(2026, 8, 23), 8.0, 14.0, wind_gust_max_kmh: 100.0, wind_direction_degrees: 225.0)
      reading(Date.new(2026, 8, 24), 8.0, 14.0, wind_gust_max_kmh: 99.9)
    end

    it 'keeps the nights that reached the frost danger temperature' do
      refresh
      expect(kept).to include(['frost', Date.new(2026, 8, 20), -1.5, 2.0], ['frost', Date.new(2026, 8, 22), 1.0, 2.0])
    end

    it 'keeps the days colder than the crop is killed at' do
      refresh
      expect(kept).to include(['killing_cold', Date.new(2026, 8, 20), -1.5, -1.0])
    end

    it 'keeps the days hotter than the crop takes' do
      refresh
      expect(kept).to include(['killing_heat', Date.new(2026, 8, 22), 33.0, 30.0])
    end

    it 'keeps the days with gusts of 100 km/h or more, with where from and the temperatures' do
      refresh
      expect(planting.conditions.damaging_wind.pluck(:occurred_on, :value, :direction_degrees, :temp_min_c, :temp_max_c))
        .to eq [[Date.new(2026, 8, 23), 100.0, 225.0, 8.0, 14.0]]
    end

    it 'keeps the days with 100 mm of rain or more' do
      reading(Date.new(2026, 8, 25), 8.0, rainfall_mm: 100.0)
      reading(Date.new(2026, 8, 26), 8.0, rainfall_mm: 99.9)
      refresh
      expect(planting.conditions.heavy_rain.pluck(:occurred_on, :value)).to eq [[Date.new(2026, 8, 25), 100.0]]
    end

    it 'keeps the days with a high over 40 °C, whatever the crop' do
      reading(Date.new(2026, 8, 25), 20.0, 40.1)
      reading(Date.new(2026, 8, 26), 20.0, 40.0)
      refresh
      expect(planting.conditions.extreme_heat.pluck(:occurred_on, :value)).to eq [[Date.new(2026, 8, 25), 40.1]]
    end

    it 'does not duplicate a day when run again' do
      2.times { described_class.refresh(planting, today:) }
      expect(planting.conditions.count).to eq 5
    end

    context 'with the weather held from the start of the winter' do
      before { hold_readings(Date.new(2026, 1, 1), Date.new(2026, 8, 17)) }

      it 'keeps the first snowfall of the winter, in the southern hemisphere' do
        reading(Date.new(2026, 8, 25), 0.0, 4.0, snowfall_cm: 3.0)
        reading(Date.new(2026, 8, 26), 0.0, 4.0, snowfall_cm: 5.0)
        refresh
        expect(planting.conditions.first_snow.pluck(:occurred_on, :value)).to eq [[Date.new(2026, 8, 25), 3.0]]
      end
    end

    context 'when snow fell before the planting went in' do
      before do
        hold_readings(Date.new(2026, 1, 1), Date.new(2026, 8, 17), except: [Date.new(2026, 8, 10)])
        reading(Date.new(2026, 8, 10), 0.0, 4.0, snowfall_cm: 2.0)
        reading(Date.new(2026, 8, 25), 0.0, 4.0, snowfall_cm: 3.0)
      end

      it 'is not the first of the winter' do
        refresh
        expect(planting.conditions.first_snow).to be_empty
      end
    end

    context 'when we do not hold the weather from the start of the winter' do
      before do
        hold_readings(Date.new(2026, 7, 1), Date.new(2026, 8, 17))
        reading(Date.new(2026, 8, 25), 0.0, 4.0, snowfall_cm: 3.0)
      end

      it 'cannot say it is the first, so keeps nothing' do
        refresh
        expect(planting.conditions.first_snow).to be_empty
      end
    end

    context 'when a day kept earlier no longer counts' do
      before { create(:planting_condition, planting:, kind: 'killing_heat', occurred_on: Date.new(2026, 8, 25)) }

      it 'drops it' do
        refresh
        expect(planting.conditions.killing_heat.pluck(:occurred_on)).to eq [Date.new(2026, 8, 22)]
      end
    end

    context 'when the crop has no EcoCrop figures' do
      let(:crop) { create(:crop) }

      it 'keeps no days of killing cold or heat' do
        refresh
        expect(planting.conditions.pluck(:kind).uniq).to contain_exactly('frost', 'damaging_wind')
      end
    end

    context 'when the garden is somewhere safe from frost' do
      before { garden.update_columns(frost_safe: true) } # rubocop:disable Rails/SkipsModelValidations

      it 'keeps nothing' do
        refresh
        expect(planting.conditions).to be_empty
      end
    end
  end
end
