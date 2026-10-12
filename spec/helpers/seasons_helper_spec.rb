# frozen_string_literal: true

require 'rails_helper'

describe SeasonsHelper do
  describe '#season_for' do
    it 'is spring in October in the southern hemisphere' do
      expect(helper.season_for(-41.3, Date.new(2026, 10, 12))).to eq :spring
    end

    it 'is autumn in October in the northern hemisphere' do
      expect(helper.season_for(51.5, Date.new(2026, 10, 12))).to eq :autumn
    end

    it 'is nil without a latitude' do
      expect(helper.season_for(nil)).to be_nil
    end
  end

  describe '#season_summary' do
    let(:member) { build(:member, location: 'Wellington', latitude: -41.3) }

    it 'names season, place, month and latitude' do
      expect(helper.season_summary(member, Date.new(2026, 10, 12))).to eq 'Spring in Wellington · October · 41°S'
    end

    it 'is nil when we do not know where they are' do
      expect(helper.season_summary(build(:member, latitude: nil))).to be_nil
    end
  end
end
