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

  describe '#heat_data?' do
    subject(:data) { build(:ecocrop_data, **attributes) }

    let(:attributes) { {} }

    it { is_expected.to be_heat_data }

    context 'without a shortest growing cycle' do
      let(:attributes) { { gmin: nil } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with a shortest growing cycle of 0 days' do
      let(:attributes) { { gmin: 0 } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with a longest growing cycle of 0 days' do
      let(:attributes) { { gmax: 0 } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with growing cycles of 0 days at both ends' do
      let(:attributes) { { gmin: 0, gmax: 0 } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with a negative growing cycle' do
      let(:attributes) { { gmin: -5 } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with an optimal temperature range of 0' do
      let(:attributes) { { topmn: 0, topmx: 0 } }

      it { is_expected.not_to be_heat_data }
    end

    context 'with a lowest growing temperature of 0' do
      let(:attributes) { { tmin: 0 } }

      it { is_expected.to be_heat_data }
    end

    context 'when the optimal temperature is no higher than the lowest the crop grows at' do
      let(:attributes) { { tmin: 25 } }

      it { is_expected.not_to be_heat_data }
    end
  end

  describe '#first_harvest_degree_days' do
    subject(:data) { build(:ecocrop_data, tmin: 10, topmn: 20, topmx: 30, gmin: 60) }

    it 'is the shortest cycle at the optimal temperature, above the lowest the crop grows at' do
      expect(data.first_harvest_degree_days).to eq 900
    end
  end

  describe 'Crop#ecocrop_heat_data' do
    subject(:heat_data) { variety.ecocrop_heat_data }

    let(:member) { create(:member) }
    let(:parent) { create(:crop, name: 'Tomato') }
    let(:variety) { create(:crop, name: 'Roma tomato', parent:) }
    let!(:tomato_data) { create(:ecocrop_data, scientificname: 'Solanum lycopersicum') }

    before { parent.scientific_names.create!(name: 'Solanum lycopersicum', creator: member) }

    context 'when only the parent crop has data' do
      it "is the parent's" do
        expect(heat_data).to eq tomato_data
      end
    end

    context 'when the variety has data of its own' do
      let!(:roma_data) { create(:ecocrop_data, scientificname: 'Solanum lycopersicum var. roma') }

      before { variety.scientific_names.create!(name: 'Solanum lycopersicum var. roma', creator: member) }

      it 'is its own' do
        expect(heat_data).to eq roma_data
      end
    end

    context 'when the variety has data that is not enough for a heat estimate' do
      before do
        create(:ecocrop_data, scientificname: 'Solanum lycopersicum var. roma', gmin: nil)
        variety.scientific_names.create!(name: 'Solanum lycopersicum var. roma', creator: member)
      end

      it "is the parent's" do
        expect(heat_data).to eq tomato_data
      end
    end

    context 'when the variety has a growing cycle of 0 days' do
      before do
        create(:ecocrop_data, scientificname: 'Solanum lycopersicum var. roma', gmin: 0, gmax: 0)
        variety.scientific_names.create!(name: 'Solanum lycopersicum var. roma', creator: member)
      end

      it "is the parent's" do
        expect(heat_data).to eq tomato_data
      end
    end

    context 'when the variety and its parent both have a growing cycle of 0 days' do
      before do
        tomato_data.update!(gmin: 0, gmax: 0)
        create(:ecocrop_data, scientificname: 'Solanum lycopersicum var. roma', gmin: 0, gmax: 0)
        variety.scientific_names.create!(name: 'Solanum lycopersicum var. roma', creator: member)
      end

      it { is_expected.to be_nil }
    end

    context 'when neither crop has data' do
      before { parent.scientific_names.destroy_all }

      it { is_expected.to be_nil }
    end
  end

  describe '.suggested_crops' do
    subject(:suggestions) { described_class.suggested_crops(described_class.all) }

    let!(:carrot) { create(:ecocrop_data, scientificname: 'Daucus carota', comname: %w(carrot)) }

    context 'with a crop named like a common name, in other case' do
      let!(:crop) { create(:crop, name: 'Carrot') }

      it('suggests it') { expect(suggestions).to eq(carrot.id => [crop]) }
    end

    context 'with a crop already linked elsewhere' do
      before { create(:crop, name: 'carrot', ecocrop_record: create(:ecocrop_data)) }

      it('leaves it out') { expect(suggestions).to be_empty }
    end

    context 'with a record that already has a crop' do
      before do
        create(:crop, name: 'carrot', ecocrop_record: carrot)
        create(:crop, name: 'Carrot', approval_status: 'approved')
      end

      it('suggests nothing') { expect(suggestions).to be_empty }
    end

    context 'without common names' do
      before { carrot.update!(comname: nil) }

      it('suggests nothing') { expect(suggestions).to be_empty }
    end
  end

  describe '#new_common_names_for' do
    let(:record) { build(:ecocrop_data, comname: ['carrot', 'Karotte ', 'karotte', 'wortel']) }
    let(:crop) { create(:crop, name: 'Carrot') }

    before { create(:alternate_name, crop:, name: 'WORTEL') }

    it 'is the tidied names the crop lacks' do
      expect(record.new_common_names_for(crop)).to eq %w(Karotte)
    end

    it 'is empty without common names' do
      record.comname = nil
      expect(record.new_common_names_for(crop)).to be_empty
    end
  end
end
