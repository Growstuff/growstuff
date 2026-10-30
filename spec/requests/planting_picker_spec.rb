# frozen_string_literal: true

require 'rails_helper'

describe 'Planting picker' do
  subject(:body) { response.parsed_body }

  let(:member) { FactoryBot.create(:member) }
  let!(:planting) { FactoryBot.create(:planting, owner: member, garden: FactoryBot.create(:garden, owner: member)) }

  context 'when signed in' do
    before do
      sign_in member
      get planting_picker_path(format: :json)
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(body.pluck('id')).to eq [planting.id] }
    it { expect(body.first['crop']).to eq('id' => planting.crop_id, 'name' => planting.crop_name) }
  end

  context 'when signed out' do
    before { get planting_picker_path(format: :json) }

    it { expect(response).to have_http_status(:unauthorized) }
  end
end
