# frozen_string_literal: true

require 'rails_helper'

describe ClimateUpdater, type: :service do
  subject(:updater) { described_class.new(client:, today:, seconds_per_call: 0) }

  let(:today) { Date.new(2026, 10, 31) }
  let(:client) { instance_double(OpenMeteoClient) }
  let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  # Every day is 10 degrees with 2 mm of rain, and 7 degrees in the soil, with a frost on 1 June and 10 September.
  let(:daily) do
    lambda do |from:, to:, **|
      (from..to).index_with do |day|
        frost = [Date.new(day.year, 6, 1), Date.new(day.year, 9, 10)].include?(day)
        { rainfall_mm: 2.0, temp_mean_c: 10.0, temp_max_c: 14.0, temp_min_c: frost ? -1.0 : 10.0, soil_temp_c: 7.0 }
      end
    end
  end

  before do
    allow(client).to receive(:daily, &daily)
    create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
  end

  context 'with a place that has no climate yet' do
    it 'does the place' do
      expect(updater.update_all).to eq 1
    end

    it 'asks for the five variables, from 30 complete frost years ago to the last day Open-Meteo has' do
      expect(client).to receive(:daily).with(latitude: -41.25, longitude: 174.75, from: Date.new(1996, 1, 1),
                                             to: Date.new(2026, 10, 26), variables: described_class::VARIABLES)
      updater.update_all
    end

    it 'saves a stat for each threshold' do
      updater.update_all
      expect(FrostStat.pluck(:threshold_c)).to contain_exactly(0.0, 2.0)
    end

    it 'saves thirty years at each threshold' do
      updater.update_all
      expect(FrostYear.where(threshold_c: 0.0).count).to eq 30
    end

    it 'finds the frost status' do
      updater.update_all
      expect(FrostStat.find_by(threshold_c: 0.0).status).to eq 'frost'
    end

    it 'finds the median last frost' do
      updater.update_all
      stat = FrostStat.find_by(threshold_c: 0.0)
      expect(stat.date_for(:last_frost_median, 2026)).to eq Date.new(2026, 9, 10)
    end

    it 'saves every month, up to this one' do
      updater.update_all
      expect(ClimateMonth.count).to eq 370
    end

    it 'adds up the rain of a month' do
      updater.update_all
      expect(ClimateMonth.find_by(year: 2025, month: 2).rain_mm).to eq 56.0
    end

    it 'counts the calls used' do
      updater.update_all
      expect(updater.calls_used).to be > 700
    end
  end

  context 'with an active garden that has no plantings' do
    before { Planting.destroy_all }

    it 'does the place' do
      garden
      expect(updater.update_all).to eq 1
    end
  end

  context 'with a nursery that has no plantings' do
    before do
      Planting.destroy_all
      garden.update_columns(nursery: true) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'leaves it out' do
      expect(updater.update_all).to eq 0
    end
  end

  context 'when the place already has its months' do
    before { create(:climate_month, latitude: -41.25, longitude: 174.75) }

    it 'leaves it alone' do
      expect(updater.update_all).to eq 0
    end

    it 'makes no calls' do
      expect(client).not_to receive(:daily)
      updater.update_all
    end
  end

  context 'when the latest months of a place are a week old' do
    before { create(:climate_month, latitude: -41.25, longitude: 174.75, year: 2026, month: 9, updated_at: Time.zone.local(2026, 10, 1)) }

    it 'brings them up to date' do
      expect(updater.update_all).to eq 1
    end

    it 'fetches only the last few whole months' do
      expect(client).to receive(:daily).with(hash_including(from: Date.new(2026, 8, 1), to: Date.new(2026, 10, 26)))
      updater.update_all
    end

    it 'saves those months' do
      updater.update_all
      expect(ClimateMonth.where(year: 2026).count).to eq 3
    end

    it 'leaves the frost dates alone' do
      updater.update_all
      expect(FrostStat.count).to eq 0
    end
  end

  context 'when the budget is too small for a place' do
    subject(:updater) { described_class.new(client:, today:, budget: 10, seconds_per_call: 0) }

    it 'leaves the place for another day' do
      expect(updater.update_all).to eq 0
    end

    it 'saves nothing' do
      updater.update_all
      expect(ClimateMonth.count + FrostStat.count).to eq 0
    end
  end

  context 'when Open-Meteo fails' do
    before { allow(client).to receive(:daily).and_raise(OpenMeteoClient::Error, 'down') }

    it 'saves nothing' do
      updater.update_all
      expect(ClimateMonth.count + FrostStat.count).to eq 0
    end
  end

  context 'with a garden without a location' do
    let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: nil, longitude: nil) } } # rubocop:disable Rails/SkipsModelValidations

    it 'does nothing' do
      expect(updater.update_all).to eq 0
    end
  end

  # Room for one new cell and nothing more, so what is done first is what the updater chose first.
  context 'with two members and room for one cell' do
    subject(:updater) { described_class.new(client:, today:, budget: cell_cost, seconds_per_call: 0) }

    let(:cell_cost) { OpenMeteoClient.call_cost(Date.new(1996, 1, 1), Date.new(2026, 10, 26), variables: described_class::VARIABLES.size) }
    let(:wellington) { -41.25 }
    let(:london) { 51.5 }
    let(:other_garden) { create(:garden).tap { |garden| garden.update_columns(latitude: 51.5, longitude: -0.1) } } # rubocop:disable Rails/SkipsModelValidations

    def last_seen(member, days_ago)
      member.update_columns(created_at: today.in_time_zone - 2.years, last_sign_in_at: today.in_time_zone - days_ago.days) # rubocop:disable Rails/SkipsModelValidations
    end

    before do
      create(:planting, garden: other_garden, owner: other_garden.owner, planted_at: today - 10)
      last_seen(garden.owner, wellington_days_ago)
      last_seen(other_garden.owner, london_days_ago)
      updater.update_all
    end

    context 'when the member of the second garden signed in more recently' do
      let(:wellington_days_ago) { 20 }
      let(:london_days_ago) { 2 }

      it 'does their cell' do
        expect(ClimateMonth.distinct.pluck(:latitude)).to eq [london]
      end
    end

    context 'when the member of the first garden signed in more recently' do
      let(:wellington_days_ago) { 2 }
      let(:london_days_ago) { 20 }

      it 'does their cell' do
        expect(ClimateMonth.distinct.pluck(:latitude)).to eq [wellington]
      end
    end

    context 'when one member has not signed in for months' do
      let(:wellington_days_ago) { 400 }
      let(:london_days_ago) { 30 }

      it 'does the active member first' do
        expect(ClimateMonth.distinct.pluck(:latitude)).to eq [london]
      end
    end
  end

  context 'when an active member has no data and an inactive member has old data' do
    subject(:updater) { described_class.new(client:, today:, budget: cell_cost, seconds_per_call: 0) }

    let(:cell_cost) { OpenMeteoClient.call_cost(Date.new(1996, 1, 1), Date.new(2026, 10, 26), variables: described_class::VARIABLES.size) }
    let(:inactive_garden) { create(:garden).tap { |garden| garden.update_columns(latitude: 51.5, longitude: -0.1) } } # rubocop:disable Rails/SkipsModelValidations

    before do
      create(:planting, garden: inactive_garden, owner: inactive_garden.owner, planted_at: today - 10)
      inactive_garden.owner.update_columns(created_at: today.in_time_zone - 1.year, last_sign_in_at: today.in_time_zone - 200.days) # rubocop:disable Rails/SkipsModelValidations
      create(:climate_month, latitude: 51.5, longitude: 0.0, year: 2026, month: 9, updated_at: today.in_time_zone - 60.days)
      updater.update_all
    end

    it 'does the active member first' do
      expect(ClimateMonth.where(latitude: -41.25)).to exist
    end

    it 'leaves the inactive member until the active are done' do
      expect(ClimateMonth.where(latitude: 51.5).count).to eq 1
    end
  end
end
