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
end
