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

    def reading(date, low, high = 12.0, gust: 20.0, direction: 270.0)
      create(:weather_reading, latitude: cell.first, longitude: cell.last, date:, temp_min_c: low, temp_max_c: high,
                               wind_gust_max_kmh: gust, wind_direction_degrees: direction)
    end

    before do
      create(:frost_stat, latitude: cell.first, longitude: cell.last, threshold_c: FrostCalculator::FROST_DANGER_C, status: 'frost',
                          first_frost_p10: 154, first_frost_median: 173, last_frost_median: 240, last_frost_p90: 274)
      reading(Date.new(2026, 8, 20), -1.5)
      reading(Date.new(2026, 8, 21), 6.0)
      reading(Date.new(2026, 8, 22), 1.0, 33.0)
      reading(Date.new(2026, 8, 23), 8.0, 14.0, gust: 100.0, direction: 225.0)
      reading(Date.new(2026, 8, 24), 8.0, 14.0, gust: 99.9)
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

    it 'does not duplicate a day when run again' do
      2.times { described_class.refresh(planting, today:) }
      expect(planting.conditions.count).to eq 5
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
