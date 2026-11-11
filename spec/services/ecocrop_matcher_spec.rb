# frozen_string_literal: true

require 'rails_helper'

describe EcocropMatcher do
  subject(:matches) { described_class.new.call.index_by { |match| match.crop.name } }

  def crop_named(name, *scientific_names)
    create(:crop, name:).tap do |crop|
      scientific_names.each { |sci| create(:scientific_name, crop:, name: sci) }
    end
  end

  describe '.binomial' do
    it 'drops the author and variety' do
      expect(described_class.binomial('Solanum lycopersicum var. cerasiforme (Dunal) A.Gray')).to eq 'solanum lycopersicum'
    end

    it 'drops the hybrid mark' do
      expect(described_class.binomial('Rubus x loganobaccus')).to eq 'rubus loganobaccus'
    end

    it 'is nil for a genus alone' do
      expect(described_class.binomial('Citrus')).to be_nil
    end

    it 'is nil for an unspecified species' do
      expect(described_class.binomial('Sorghum spp.')).to be_nil
    end
  end

  describe '#call' do
    let!(:cucumber) { create(:ecocrop_data, scientificname: 'Cucumis sativus') }
    let!(:tomato) { create(:ecocrop_data, scientificname: 'Lycopersicon esculentum', syno: ['Solanum lycopersicum L.']) }

    context 'with the name EcoCrop uses' do
      before { crop_named('cucumber', 'cucumis sativus') }

      it('matches exactly') { expect(matches['cucumber'].how).to eq :exact }
      it('is linkable') { expect(matches['cucumber'].record).to eq cucumber }
    end

    context 'with a name EcoCrop has only as a synonym with an author' do
      before { crop_named('tomato', 'Solanum lycopersicum') }

      it('matches by synonym') { expect(matches['tomato'].how).to eq :synonym }
      it('is linkable') { expect(matches['tomato'].record).to eq tomato }
    end

    context 'with a cultivar after the species' do
      before { crop_named('burpee cucumber', "Cucumis sativus 'Burpee'") }

      it('matches by species') { expect(matches['burpee cucumber'].how).to eq :species }
      it('is linkable') { expect(matches['burpee cucumber'].record).to eq cucumber }
    end

    context 'with several EcoCrop records for the species and none plain' do
      before do
        create(:ecocrop_data, scientificname: 'Brassica rapa Pak Choi')
        create(:ecocrop_data, scientificname: 'Brassica rapa var. rapifera')
        crop_named('mizuna', 'Brassica rapa')
      end

      it('is ambiguous') { expect(matches['mizuna'].how).to eq :ambiguous }
      it('is not linkable') { expect(matches['mizuna']).not_to be_linkable }
      it('offers both') { expect(matches['mizuna'].candidates.size).to eq 2 }
    end

    context 'with several EcoCrop records for the species and one plain' do
      let!(:plain) { create(:ecocrop_data, scientificname: 'Brassica rapa') }

      before do
        create(:ecocrop_data, scientificname: 'Brassica rapa var. rapifera')
        crop_named('mizuna', 'Brassica rapa subsp. nipposinica')
      end

      it('picks the plain species') { expect(matches['mizuna'].record).to eq plain }
    end

    context 'with a genus only' do
      before { crop_named('citrus', 'Citrus') }

      it('finds nothing') { expect(matches['citrus'].how).to eq :none }
    end

    context 'without a scientific name but with an EcoCrop common name' do
      before do
        cucumber.update!(comname: %w(cucumber))
        crop_named('cucumber')
      end

      it('suggests it') { expect(matches['cucumber'].how).to eq :common_name }
      it('does not link it') { expect(matches['cucumber']).not_to be_linkable }
    end

    context 'when the crop is already linked' do
      before { crop_named('cucumber', 'Cucumis sativus').update!(ecocrop_record: cucumber) }

      it('leaves it out') { expect(matches).to be_empty }
    end
  end
end
