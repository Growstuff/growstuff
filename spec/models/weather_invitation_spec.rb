# frozen_string_literal: true

require 'rails_helper'

describe WeatherInvitation, flipper: :planting_weather do
  subject(:invitation) { described_class.new(member, today: Date.new(2026, 11, 8)) }

  context 'without a location' do
    let(:member) { create(:member) }

    it { expect(invitation.state).to eq :no_location }
  end

  context 'with a location and no weather saved' do
    let(:member) { create(:london_member) }

    it { expect(invitation.state).to eq :loading }
  end

  context 'with a location and frost dates' do
    let(:member) { create(:london_member) }

    before { create(:frost_stat, latitude: 51.5, longitude: 0.0, threshold_c: FrostCalculator::FROST_DANGER_C) }

    it { expect(invitation.state).to eq :ready }
  end

  context 'with a location and months of weather' do
    let(:member) { create(:london_member) }

    before { create(:climate_month, latitude: 51.5, longitude: 0.0, year: 2025, month: 1) }

    it { expect(invitation.state).to eq :ready }
  end

  describe '#place_name' do
    let(:member) { build(:member, location: 'Wellington, Wellington Region, New Zealand') }

    it { expect(invitation.place_name).to eq 'Wellington' }
  end

  describe '.enabled?' do
    it { expect(described_class).to be_enabled }

    context 'when the weather feature is off', flipper: [] do
      it { expect(described_class).not_to be_enabled }
    end
  end
end
