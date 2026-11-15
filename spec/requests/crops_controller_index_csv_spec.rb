# frozen_string_literal: true

require 'rails_helper'

describe 'Crops index as CSV' do
  subject(:row) { CSV.parse(response.body, headers: true).detect { |line| line['Id'] == crop.id.to_s } }

  let(:crop) { create(:crop) }

  before do
    create_list(:seed, 2, crop:)
    create(:harvest, crop:)
    get crops_path(format: 'csv')
  end

  it { expect(response).to have_http_status(:ok) }
  it { expect(row['Seeds count']).to eq '2' }
  it { expect(row['Harvests count']).to eq '1' }
end
