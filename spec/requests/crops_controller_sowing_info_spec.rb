# frozen_string_literal: true

require 'rails_helper'

describe CropsController do
  let(:crop) { create(:crop, name: 'beetroot') }

  context 'when signed in' do
    before do
      sign_in create(:member)
      get sowing_info_crop_path(crop, format: :json)
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.parsed_body).to include('name' => 'beetroot') }
  end

  context 'when signed out' do
    before { get sowing_info_crop_path(crop, format: :json) }

    it { expect(response).to have_http_status(:unauthorized) }
  end
end
