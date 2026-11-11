# frozen_string_literal: true

require 'rails_helper'

describe SeasonalClimate do
  subject(:climate) { described_class.new(ClimateMonth.all, latitude:, today:) }

  let(:today) { Date.new(2026, 11, 10) }
  let(:latitude) { -41.3 }

  # Every month of 2024 and 2025: January to March are hot, April to September mild, October to December cool.
  def create_year(year, mean_by_month)
    mean_by_month.each do |month, mean|
      create(:climate_month, year:, month:, temp_mean_c: mean, temp_max_c: mean + 8, temp_min_c: mean - 8, rain_mm: month * 10.0)
    end
  end

  before do
    mean_by_month = (1..12).index_with { |month| month * 1.0 }
    create_year(2024, mean_by_month)
    create_year(2025, mean_by_month.transform_values { |mean| mean + 2 })
  end

  def season(name)
    climate.seasons.find { |season| season.name == name }
  end

  describe '#seasons' do
    it 'lists the four seasons, starting at spring' do
      expect(climate.seasons.map(&:name)).to eq %i(spring summer autumn winter)
    end

    it 'gives the usual average of each month' do
      expect(climate.monthly_means[1]).to eq 2.0
    end

    it 'says when the season in progress started' do
      expect(climate.starts_on(season(:spring))).to eq Date.new(2026, 9, 1)
    end

    it 'says when the next season starts' do
      expect(climate.starts_on(season(:autumn))).to eq Date.new(2027, 3, 1)
    end

    it 'says when a season that began last year started, from its months' do
      expect(climate.starts_on(season(:summer))).to eq Date.new(2026, 12, 1)
    end

    it 'is due today for the season in progress' do
      expect(climate.due_on(season(:spring))).to eq today
    end

    it 'is due when the next season starts' do
      expect(climate.due_on(season(:autumn))).to eq Date.new(2027, 3, 1)
    end

    it 'says a crop that takes 90 days from the start of spring is ready in late spring' do
      expect(climate.ready(season(:spring), 90)).to eq(part: :late, season: :spring)
    end

    it 'says a crop that takes 60 days from the start of spring is ready in mid spring' do
      expect(climate.ready(season(:spring), 60)).to eq(part: :mid, season: :spring)
    end

    it 'says a crop that takes 185 days from the start of spring is ready in early autumn' do
      expect(climate.ready(season(:spring), 185)).to eq(part: :early, season: :autumn)
    end

    it 'selects the season by name' do
      expect(climate.selected('summer').name).to eq :summer
    end

    it 'selects the current season for an unknown name' do
      expect(climate.selected('monsoon').name).to eq :spring
    end

    it 'selects the current season with no name' do
      expect(climate.selected(nil).name).to eq :spring
    end

    it 'gives how cold the nights usually get in a month' do
      expect(climate.monthly_nights[1]).to eq(-6.0)
    end

    it 'gives how hot the days usually get in a month' do
      expect(climate.monthly_days[1]).to eq 10.0
    end

    it 'gives each its months, in the southern hemisphere' do
      expect(season(:summer).months).to eq [12, 1, 2]
    end

    it 'puts the seasons the other way round in the northern hemisphere' do
      expect(described_class.new(ClimateMonth.all, latitude: 51.5, today:).seasons.find { |s| s.name == :summer }.months).to eq [6, 7, 8]
    end

    it 'averages the temperature over the months and years of the season' do
      # Summer: Dec 12, Jan 1, Feb 2 (means 12, 1, 2 in 2024 and 14, 3, 4 in 2025): a total of 36 over six months.
      expect(season(:summer).mean).to eq 6.0
    end

    it 'gives how cold the nights typically fall' do
      expect(season(:summer).night).to eq(-2.0)
    end

    it 'gives how hot the days typically get' do
      expect(season(:summer).day).to eq 14.0
    end

    it 'adds up the usual rain of the months' do
      # Rain is 10 a month times the month number: Dec 120, Jan 10, Feb 20.
      expect(season(:summer).rain).to eq 150.0
    end

    it 'marks the season it is now' do
      expect(climate.seasons.select(&:current).map(&:name)).to eq [:spring]
    end
  end

  describe 'a year still in progress' do
    before { create(:climate_month, year: 2026, month: 11, temp_mean_c: 40.0, temp_max_c: 50.0, temp_min_c: 30.0, rain_mm: 999.0) }

    it 'is not counted in the usual figures' do
      expect(season(:spring).mean).not_to be > 30
    end

    it 'does not count towards the years held' do
      expect(climate.years).to eq 2
    end
  end

  describe '#years' do
    it 'counts the complete years held' do
      expect(climate.years).to eq 2
    end
  end

  context 'with nothing held for a season' do
    before { ClimateMonth.where(month: [12, 1, 2]).delete_all }

    it 'has no figures for it' do
      expect(season(:summer).to_h.values_at(:mean, :night, :day, :rain)).to all(be_nil)
    end

    it 'still has the other seasons' do
      expect(season(:winter).mean).to be_present
    end
  end

  describe '.for' do
    def member_at(latitude, longitude)
      create(:member).tap { |member| member.update_columns(latitude:, longitude:) } # rubocop:disable Rails/SkipsModelValidations
    end

    it 'finds the climate of the weather cell of the member\'s place' do
      expect(described_class.for(member_at(-41.3, 174.7), today:)).to be_a described_class
    end

    it 'is nil for a member with no location' do
      expect(described_class.for(member_at(nil, nil), today:)).to be_nil
    end

    it 'is nil when nothing is held for their cell yet' do
      expect(described_class.for(member_at(10.0, 10.0), today:)).to be_nil
    end
  end
end
