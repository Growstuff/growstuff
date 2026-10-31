# frozen_string_literal: true

require 'rails_helper'

describe WeatherUpdater, type: :service do
  subject(:updater) { described_class.new(client:, today:, delay: 0) }

  let(:today) { Date.new(2026, 10, 31) }
  let(:client) { instance_double(OpenMeteoClient) }
  let(:garden) { garden_at(-41.29, 174.78) }
  let(:day) { { rainfall_mm: 6.4, temp_max_c: 13.2 } }

  # The garden geocodes its location on save, so set the coordinates after.
  def garden_at(latitude, longitude)
    create(:garden).tap { |garden| garden.update_columns(latitude:, longitude:) } # rubocop:disable Rails/SkipsModelValidations
  end

  before do
    allow(client).to receive(:daily) { |from:, to:, **| (from..to).index_with { day } }
  end

  context 'with an active planting in a garden with a location' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 10) }

    it 'saves a reading for each day up to the lag' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(6)
    end

    it 'records where the reading came from' do
      updater.update_all
      expect(WeatherReading.first.source).to eq 'open-meteo'
    end

    it 'keys readings to the grid cell' do
      updater.update_all
      expect(WeatherReading.first.attributes.values_at('latitude', 'longitude')).to eq [-41.25, 174.75]
    end

    it 'only asks for days it lacks on a second run' do
      expect(client).to(receive(:daily).once { |from:, to:, **| (from..to).index_with { day } })
      2.times { updater.update_all }
    end
  end

  context 'with two plantings in the same grid cell' do
    before do
      create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
      other = garden_at(-41.30, 174.80)
      create(:planting, garden: other, owner: other.owner, planted_at: today - 10)
    end

    it 'makes one request' do
      expect(client).to(receive(:daily).once { |from:, to:, **| (from..to).index_with { day } })
      updater.update_all
    end
  end

  context 'with a planting older than the current window' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 100) }

    it 'fills in history when the budget allows' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(96)
    end

    context 'with a budget for current weather only' do
      subject(:updater) { described_class.new(client:, today:, delay: 0, budget: 6) }

      it 'saves the current days and no history' do
        expect { updater.update_all }.to change(WeatherReading, :count).by(30)
      end
    end

    it 'counts a long request as several calls' do
      updater.update_all
      expect(updater.calls_used).to be > 2
    end
  end

  context 'with a planting from years ago still marked active' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 4000) }

    it 'saves only its first year' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(367)
    end
  end

  context 'with a finished planting' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 10, finished: true, finished_at: today - 5) }

    it 'saves nothing' do
      expect { updater.update_all }.not_to change(WeatherReading, :count)
    end
  end

  context 'with a garden without a location' do
    before do
      bare = garden_at(nil, nil)
      create(:planting, garden: bare, owner: bare.owner, planted_at: today - 10)
    end

    it 'saves nothing' do
      expect { updater.update_all }.not_to change(WeatherReading, :count)
    end
  end

  context 'when the weather service fails' do
    before do
      create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
      allow(client).to receive(:daily).and_raise(OpenMeteoClient::Error, 'down')
    end

    it 'saves nothing and carries on' do
      expect { updater.update_all }.not_to change(WeatherReading, :count)
    end
  end
end
