# frozen_string_literal: true

require 'rails_helper'

describe SuggestedPlantJob do
  subject(:suggested) { described_class.new(member, climate) }

  let(:member) { create(:member) }
  let(:crop) { create(:crop, name: 'corn') }
  let(:today) { Date.new(2026, 11, 10) }
  let(:climate) do
    create(:climate_month, year: 2025, month: 7)
    SeasonalClimate.new(ClimateMonth.all, latitude: -41.3, today:)
  end

  describe '#name' do
    it 'names the crop and the season, with its year' do
      expect(suggested.name(crop, 'spring')).to eq 'Plant corn for spring 2026'
    end

    it 'gives the year the next season starts in' do
      expect(suggested.name(crop, 'autumn')).to eq 'Plant corn for autumn 2027'
    end

    it 'names only the crop without a season' do
      expect(suggested.name(crop, nil)).to eq 'Plant corn'
    end
  end

  describe '#add' do
    it 'makes a job linked to the crop' do
      expect(suggested.add(crop, 'spring')).to have_attributes(jobbable: crop, action: 'plant', name: 'Plant corn for spring 2026')
    end

    it 'is due today for the season in progress' do
      expect(suggested.add(crop, 'spring').due_date).to eq today
    end

    it 'is due when the season starts for one to come' do
      expect(suggested.add(crop, 'autumn').due_date).to eq Date.new(2027, 3, 1)
    end

    it 'makes none while the member has it' do
      suggested.add(crop, 'spring')
      expect(described_class.new(member, climate).add(crop, 'spring')).to be_nil
    end

    it 'makes one for another season of the same crop' do
      suggested.add(crop, 'spring')
      expect(described_class.new(member, climate).add(crop, 'summer')).to be_present
    end

    it 'makes another once the first is done' do
      suggested.add(crop, 'spring').update!(finished: true)
      expect(described_class.new(member, climate).add(crop, 'spring')).to be_present
    end
  end

  describe '#planned?' do
    it 'is false before it is added' do
      expect(suggested).not_to be_planned(crop, 'spring')
    end

    it 'is true once it is added' do
      suggested.add(crop, 'spring')
      expect(described_class.new(member, climate)).to be_planned(crop, 'spring')
    end
  end
end
