# frozen_string_literal: true

require 'rails_helper'

describe NearestClimate do
  describe '.to' do
    subject(:nearest) { described_class.to(-41.3, 174.8) }

    context 'without any weather' do
      it { is_expected.to be_nil }
    end

    context 'with weather held at two cells' do
      before do
        create(:climate_month, latitude: 51.5, longitude: 0.0)
        create(:climate_month)
      end

      it 'picks the closer cell' do
        expect(nearest.latitude).to eq(-41.25)
      end

      it 'is not far' do
        expect(nearest).not_to be_far
      end
    end

    context 'when the nearest weather is far away' do
      before { create(:climate_month, latitude: 51.5, longitude: 0.0) }

      it { is_expected.to be_far }
    end

    it 'is nil for a latitude that does not exist' do
      expect(described_class.to(120, 0)).to be_nil
    end
  end
end
