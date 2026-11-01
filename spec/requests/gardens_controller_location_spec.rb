# frozen_string_literal: true

require 'rails_helper'

describe GardensController do
  include Devise::Test::IntegrationHelpers

  let(:member) { create_located_member('Wellington, New Zealand', -41.2887, 174.7772) }

  before { sign_in member }

  describe 'POST /gardens' do
    subject(:garden) { Garden.find_by(name: 'Allotment') }

    before { post gardens_path, params: { garden: { name: 'Allotment', location: 'nowhere real', latitude: 1, longitude: 2 } } }

    it 'starts at the place its owner gardens' do
      expect(garden.location).to eq 'Wellington, New Zealand'
    end
  end

  describe 'PATCH /gardens/:slug' do
    let(:garden) { create(:garden, owner: member) }

    it 'ignores a typed location' do
      garden.update_columns(location: 'Dunedin') # rubocop:disable Rails/SkipsModelValidations
      patch garden_path(garden), params: { garden: { location: 'nowhere real' } }
      expect(garden.reload.location).to eq 'Dunedin'
    end
  end
end
