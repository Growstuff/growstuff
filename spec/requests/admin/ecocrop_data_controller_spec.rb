# frozen_string_literal: true

require 'rails_helper'

describe Admin::EcocropDataController do
  let!(:matched) { create(:ecocrop_data, scientificname: 'Cucumis sativus', comname: nil, syno: nil) }

  before do
    create(:ecocrop_data, scientificname: 'Daucus carota', comname: %w(carrot))
    create(:crop, name: 'cucumber', ecocrop_record: matched)
  end

  describe '#index' do
    context 'with a crop wrangler' do
      before { sign_in create(:crop_wrangling_member) }

      it 'lists every record' do
        get admin_ecocrop_data_path
        expect(response.body).to include('Cucumis sativus', 'Daucus carota')
      end

      it 'names the crop a record is matched to' do
        get admin_ecocrop_data_path
        expect(response.body).to include('cucumber')
      end

      it 'lists only the matched records' do
        get admin_ecocrop_data_path(filter: 'matched')
        expect(response.body).not_to include('Daucus carota')
      end

      it 'lists only the unmatched records' do
        get admin_ecocrop_data_path(filter: 'unmatched')
        expect(response.body).not_to include('Cucumis sativus')
      end

      it 'suggests a crop named like a common name' do
        create(:crop, name: 'Carrot')
        get admin_ecocrop_data_path
        expect(response.body).to include(admin_link_ecocrop_data_path(EcocropData.find_by!(scientificname: 'Daucus carota')))
      end

      it 'searches common names' do
        get admin_ecocrop_data_path(q: 'carrot')
        expect(response.body).not_to include('Cucumis sativus')
      end
    end

    context 'with an ordinary member' do
      before { sign_in create(:member) }

      it 'is refused' do
        get admin_ecocrop_data_path
        expect(response).not_to be_successful
      end
    end
  end

  describe '#link' do
    let(:crop) { create(:crop, name: 'carrot') }
    let(:record) { EcocropData.find_by!(scientificname: 'Daucus carota') }

    context 'with a crop wrangler' do
      before { sign_in create(:crop_wrangling_member) }

      it 'links the crop to the record' do
        expect { post admin_link_ecocrop_data_path(record), params: { crop_id: crop.id } }
          .to change { crop.reload.ecocrop_record }.to(record)
      end

      it 'moves a crop off the record it had' do
        crop.update!(ecocrop_record: matched)
        post admin_link_ecocrop_data_path(record), params: { crop_id: crop.id }
        expect(matched.crops).not_to include(crop)
      end
    end

    context 'with names ticked' do
      before { sign_in create(:crop_wrangling_member) }

      it 'copies them to the crop' do
        record.update!(comname: %w(carrot karotte))
        post admin_link_ecocrop_data_path(record), params: { crop_id: crop.id, names: %w(karotte) }
        expect(crop.alternate_names.pluck(:name)).to eq %w(karotte)
      end
    end

    context 'with an ordinary member' do
      before { sign_in create(:member) }

      it 'does not link' do
        post admin_link_ecocrop_data_path(record), params: { crop_id: crop.id }
        expect(crop.reload.ecocrop_record).to be_nil
      end
    end
  end

  describe '#unlink' do
    before { sign_in create(:crop_wrangling_member) }

    it 'unlinks the crop' do
      crop = matched.crops.first
      expect { delete admin_link_ecocrop_data_path(matched), params: { crop_id: crop.id } }
        .to change { crop.reload.ecocrop_record }.to(nil)
    end
  end

  describe '#create_crop' do
    subject(:create_it) { post admin_create_crop_ecocrop_data_path(record), params: }

    let(:record) { EcocropData.find_by!(scientificname: 'Daucus carota') }
    let(:params) { { name: 'carrot', en_wikipedia_url: 'https://en.wikipedia.org/wiki/Carrot' } }

    context 'with a crop wrangler' do
      before { sign_in create(:crop_wrangling_member) }

      it 'creates the crop' do
        expect { create_it }.to change(Crop, :count).by(1)
      end

      it 'links the new crop to the record' do
        create_it
        expect(record.reload.crops.pluck(:name)).to eq %w(carrot)
      end

      context 'without a Wikipedia page' do
        let(:params) { { name: 'carrot' } }

        it('creates nothing') { expect { create_it }.not_to change(Crop, :count) }
      end

      context 'without a name' do
        let(:params) { { name: '', en_wikipedia_url: 'https://en.wikipedia.org/wiki/Carrot' } }

        it('creates nothing') { expect { create_it }.not_to change(Crop, :count) }
      end
    end

    context 'with an ordinary member' do
      before { sign_in create(:member) }

      it 'creates nothing' do
        expect { create_it }.not_to change(Crop, :count)
      end
    end
  end

  describe '#search' do
    let!(:wild) { create(:ecocrop_data, scientificname: 'Pastinaca sativa', comname: %w(parsnip wild-parsnip)) }

    before { create(:ecocrop_data, scientificname: 'Pastinaca weed', comname: ['parsnip weed']) }

    context 'with a crop wrangler' do
      before { sign_in create(:crop_wrangling_member) }

      it 'finds records by common name, exact matches first' do
        get admin_search_ecocrop_data_path(q: 'parsnip', format: :json)
        expect(response.parsed_body.pick('scientific_name')).to eq 'Pastinaca sativa'
      end

      it 'gives the common names' do
        get admin_search_ecocrop_data_path(q: 'parsnip', format: :json)
        expect(response.parsed_body.first['common_names']).to eq %w(parsnip wild-parsnip)
      end

      it 'names the crops a record is linked to' do
        create(:crop, name: 'baby parsnip', ecocrop_record: wild)
        get admin_search_ecocrop_data_path(q: 'parsnip', format: :json)
        expect(response.parsed_body.first['crops']).to eq ['baby parsnip']
      end

      it 'finds nothing for a blank search' do
        get admin_search_ecocrop_data_path(q: ' ', format: :json)
        expect(response.parsed_body).to be_empty
      end
    end

    context 'with an ordinary member' do
      before { sign_in create(:member) }

      it 'is refused' do
        get admin_search_ecocrop_data_path(q: 'parsnip', format: :json)
        expect(response).not_to be_successful
      end
    end
  end
end
