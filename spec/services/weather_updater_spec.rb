# frozen_string_literal: true

require 'rails_helper'

describe WeatherUpdater, type: :service do
  subject(:updater) { described_class.new(client:, today:, seconds_per_call: 0) }

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

    it 'saves a reading for each day from a year before planting up to the lag' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(371)
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
      expect(client).to(receive(:daily).twice { |from:, to:, **| (from..to).index_with { day } })
      2.times { updater.update_all }
    end
  end

  context 'with two plantings in the same grid cell' do
    before do
      create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
      other = garden_at(-41.30, 174.80)
      create(:planting, garden: other, owner: other.owner, planted_at: today - 10)
    end

    it 'asks once for current weather and once for history' do
      expect(client).to(receive(:daily).twice { |from:, to:, **| (from..to).index_with { day } })
      updater.update_all
    end
  end

  context 'with a planting older than the current window' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 100) }

    it 'fills in history when the budget allows' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(461)
    end

    context 'with a budget for current weather only' do
      subject(:updater) { described_class.new(client:, today:, seconds_per_call: 0, budget: 6) }

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

    it 'saves its first year, and the year before' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(732)
    end
  end

  context 'with a planting still growing' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 10) }

    it 'also fetches the year before it started' do
      expect { updater.update_all }.to change { WeatherReading.exists?(date: today - 10 - 200) }.to(true)
    end
  end

  context 'with a planting running late' do
    before { create(:planting, crop: create(:crop, median_lifespan: 20), garden:, owner: garden.owner, planted_at: today - 100) }

    it 'carries on fetching while it grows' do
      updater.update_all
      expect(WeatherReading.maximum(:date)).to eq today - WeatherUpdater::LAG_DAYS
    end
  end

  context 'with a planting finished long ago' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 100, finished: true, finished_at: today - 60) }

    it 'saves nothing' do
      expect { updater.update_all }.not_to change(WeatherReading, :count)
    end
  end

  context 'with a planting that finished a few days ago' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 10, finished: true, finished_at: today - 5) }

    it 'still collects its last days' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(6)
    end
  end

  context 'when a planting finishes between runs' do
    let!(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: today - 10) }

    it 'collects the days up to its finish date on a later run' do
      updater.update_all
      planting.update!(finished: true, finished_at: today - 2)
      described_class.new(client:, today: today + 6, seconds_per_call: 0).update_all
      expect(WeatherReading.maximum(:date)).to eq today - 2
    end
  end

  context 'with a planting whose finish date is still to come' do
    before { create(:planting, garden:, owner: garden.owner, planted_at: today - 10, finished_at: today + 30) }

    it 'saves its readings' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(371)
    end
  end

  context 'with an old planting and a new one in the same grid cell' do
    before do
      create(:planting, garden:, owner: garden.owner, planted_at: today - 4000)
      create(:planting, garden:, owner: garden.owner, planted_at: today - 10)
    end

    it 'saves each planting\'s own stretch' do
      expect { updater.update_all }.to change(WeatherReading, :count).by(732 + 371)
    end

    it 'leaves out the years between them' do
      updater.update_all
      expect(WeatherReading.where(date: (today - 2000)..(today - 1000))).to be_empty
    end
  end

  context 'with a planting in a nursery' do
    before do
      nursery = create(:garden, nursery: true).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } # rubocop:disable Rails/SkipsModelValidations
      create(:planting, garden: nursery, owner: nursery.owner, planted_at: today - 10)
    end

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
