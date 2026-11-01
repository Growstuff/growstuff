# frozen_string_literal: true

require 'rails_helper'

describe EcocropData do
  describe 'validations' do
    it 'requires ecoportcode' do
      record = described_class.new(scientificname: 'Solanum lycopersicum')
      expect(record).not_to be_valid
    end

    it 'requires scientificname' do
      record = described_class.new(ecoportcode: 123)
      expect(record).not_to be_valid
    end

    it 'enforces uniqueness of ecoportcode' do
      described_class.create!(ecoportcode: 9999, scientificname: 'Test species')
      duplicate = described_class.new(ecoportcode: 9999, scientificname: 'Another species')
      expect(duplicate).not_to be_valid
    end
  end

  describe '.by_scientific_name' do
    before do
      described_class.create!(
        ecoportcode:    1001,
        scientificname: 'Zea mays',
        topmn:          18,
        topmx:          32
      )
    end

    it 'matches case-insensitively' do
      expect(described_class.by_scientific_name('zea mays')).to be_present
    end

    it 'strips whitespace when matching' do
      expect(described_class.by_scientific_name('  Zea mays  ')).to be_present
    end

    it 'returns nil when given blank or unmatched name' do
      expect(described_class.by_scientific_name('')).to be_nil
    end
  end

  describe 'Crop#ecocrop_data' do
    let(:crop) { create(:crop, name: 'Maize') }
    let(:member) { create(:member) }

    context 'when crop has a matching scientific name' do
      before do
        described_class.create!(
          ecoportcode:    2002,
          scientificname: 'Zea mays',
          topmn:          18,
          topmx:          32
        )
        crop.scientific_names.create!(name: 'Zea mays', creator: member)
      end

      it 'returns the matching ecocrop_data record' do
        expect(crop.ecocrop_data).to be_present
        expect(crop.ecocrop_data.ecoportcode).to eq(2002)
      end
    end

    context 'when crop has no scientific name' do
      it 'returns nil' do
        expect(crop.ecocrop_data).to be_nil
      end
    end

    context 'when crop scientific name does not match ecocrop' do
      before do
        crop.scientific_names.create!(name: 'Unknown species', creator: member)
      end

      it 'returns nil' do
        expect(crop.ecocrop_data).to be_nil
      end
    end
  end
end
