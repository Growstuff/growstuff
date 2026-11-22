# frozen_string_literal: true

require 'rails_helper'

describe Admin::EcocropDataHelper do
  describe '#ecocrop_details' do
    subject(:details) { helper.ecocrop_details(record) }

    let(:record) do
      build(:ecocrop_data, scientificname: 'Daucus carota', auth: 'L.', comname: %w(carrot Carrot karotte),
                           famname: 'Magnoliopsida:Asteridae:Apiales:Apiaceae', cat: %w(vegetables), lifo: %w(herb))
    end

    it('gives the scientific name with its author') { expect(details[:scientific_name]).to eq 'Daucus carota L.' }
    it('gives every common name once') { expect(details[:common_names]).to eq %w(carrot karotte) }
    it('gives the family, the last of the taxonomy') { expect(details[:family]).to eq 'Apiaceae' }
    it('gives the category') { expect(details[:category]).to eq 'vegetables' }
    it('gives the life form') { expect(details[:life_form]).to eq 'herb' }

    context 'without common names or a taxonomy' do
      let(:record) { build(:ecocrop_data, comname: nil, famname: nil, cat: nil, lifo: nil) }

      it('leaves them out') { expect(details.keys).to eq [:scientific_name] }
    end
  end
end
