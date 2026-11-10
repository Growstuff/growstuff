# frozen_string_literal: true

require 'rails_helper'

describe EcocropCropLinker do
  subject(:linker) { described_class.new(record:, member:) }

  let(:member) { create(:crop_wrangling_member) }
  let(:record) { create(:ecocrop_data, scientificname: 'Daucus carota', comname: ['carrot', 'Carrots ', 'karotte', 'carrot']) }

  describe '#link' do
    let(:crop) { create(:crop, name: 'carrot') }

    it 'links the crop to the record' do
      expect { linker.link(crop) }.to change { crop.reload.ecocrop_record }.to(record)
    end

    it 'adds the chosen names' do
      linker.link(crop, names: %w(karotte))
      expect(crop.alternate_names.pluck(:name)).to eq %w(karotte)
    end

    it 'says how many names it added' do
      expect(linker.link(crop, names: %w(karotte Carrots))).to eq 2
    end

    it 'does not add the crop\'s own name again' do
      linker.link(crop, names: %w(carrot))
      expect(crop.alternate_names).to be_empty
    end

    it 'does not add a name it already has, in other case' do
      create(:alternate_name, crop:, name: 'KAROTTE')
      expect { linker.link(crop, names: %w(karotte)) }.not_to change(AlternateName, :count)
    end

    it 'does not add a name EcoCrop does not have' do
      linker.link(crop, names: ['made up'])
      expect(crop.alternate_names).to be_empty
    end

    it 'adds names as the member' do
      linker.link(crop, names: %w(karotte))
      expect(crop.alternate_names.first.creator).to eq member
    end
  end

  describe '#create_crop' do
    subject(:crop) { linker.create_crop(name: 'carrot', wikipedia_url: 'https://en.wikipedia.org/wiki/Carrot', names: %w(karotte carrot)) }

    it('creates an approved crop') { expect(crop).to be_approved }
    it('credits the member') { expect(crop.creator).to eq member }
    it('links it to the record') { expect(crop.ecocrop_record).to eq record }
    it('gives it the scientific name') { expect(crop.scientific_names.pluck(:name)).to eq ['Daucus carota'] }
    it('adds the chosen names but not its own name') { expect(crop.alternate_names.pluck(:name)).to eq %w(karotte) }

    context 'when a crop has that name' do
      before { create(:crop, name: 'Carrot') }

      it 'refuses' do
        expect { crop }.to raise_error(described_class::Error)
      end
    end

    context 'without a Wikipedia page' do
      it 'refuses' do
        expect { linker.create_crop(name: 'carrot', wikipedia_url: '') }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end

    context 'without a name' do
      it 'refuses' do
        expect { linker.create_crop(name: ' ', wikipedia_url: 'https://en.wikipedia.org/wiki/Carrot') }
          .to raise_error(described_class::Error)
      end
    end
  end
end
