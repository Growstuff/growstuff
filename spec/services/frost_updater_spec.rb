# frozen_string_literal: true

require 'rails_helper'

describe FrostUpdater, type: :service do
  subject(:updater) { described_class.new(client:, today:, seconds_per_call: 0) }

  let(:today) { Date.new(2026, 10, 31) }
  let(:client) { instance_double(OpenMeteoClient) }
  let(:garden) { create(:garden).tap { |garden| garden.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
  # Every day is 10 degrees, with a frost on 1 June and 10 September.
  let(:minimums) do
    lambda do |from:, to:, **|
      (from..to).to_h { |day| [day, [Date.new(day.year, 6, 1), Date.new(day.year, 9, 10)].include?(day) ? -1.0 : 10.0] }
    end
  end

  before do
    allow(client).to receive(:minimums, &minimums)
    create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
  end

  context 'with a place that has no frost dates yet' do
    it 'does the place' do
      expect(updater.update_all).to eq 1
    end

    it 'asks for 30 complete frost years, ending last December in the south' do
      updater.update_all
      expect(client).to have_received(:minimums).with(latitude: -41.25, longitude: 174.75, from: Date.new(1995, 1, 1), to: Date.new(2025, 12, 31)).or have_received(:minimums).with(hash_including(from: Date.new(1996, 1, 1), to: Date.new(2025, 12, 31)))
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

    it 'counts the calls used' do
      updater.update_all
      expect(updater.calls_used).to be > 700
    end
  end

  context 'when the place already has frost dates' do
    before { create(:frost_stat, latitude: -41.25, longitude: 174.75) }

    it 'leaves it alone' do
      expect(updater.update_all).to eq 0
    end

    it 'makes no calls' do
      updater.update_all
      expect(client).not_to have_received(:minimums)
    end
  end

  context 'when the budget is too small for a place' do
    subject(:updater) { described_class.new(client:, today:, budget: 10, seconds_per_call: 0) }

    it 'leaves the place for another day' do
      expect(updater.update_all).to eq 0
    end

    it 'saves nothing' do
      updater.update_all
      expect(FrostStat.count).to eq 0
    end
  end

  context 'when Open-Meteo fails' do
    before { allow(client).to receive(:minimums).and_raise(OpenMeteoClient::Error, 'down') }

    it 'saves nothing' do
      updater.update_all
      expect(FrostStat.count).to eq 0
    end
  end

  context 'with a nursery or a garden without a location' do
    let(:garden) { create(:garden, latitude: nil, longitude: nil) }

    it 'does nothing' do
      expect(updater.update_all).to eq 0
    end
  end

  context 'when the place already holds some minimums' do
    before do
      (Date.new(2000, 1, 1)..Date.new(2025, 12, 31)).each_slice(1000) do |days|
        WeatherReading.insert_all(days.map { |day| { latitude: -41.25, longitude: 174.75, date: day, source: 'open-meteo', temp_min_c: 10.0 } }) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    it 'fetches only the dates it lacks' do
      updater.update_all
      expect(client).to have_received(:minimums).with(hash_including(from: Date.new(1996, 1, 1), to: Date.new(1999, 12, 31)))
    end
  end
end
