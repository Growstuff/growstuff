# frozen_string_literal: true

require 'rails_helper'

# The dialog on a planting that asks where its garden is: it looks places up with
# GET /places/suggest and saves the one they pick with PATCH /gardens/:slug/location.
describe 'Setting where a garden is' do
  include Devise::Test::IntegrationHelpers

  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:place) { { name: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772 } }

  def save(location)
    patch garden_location_path(garden, format: :json), params: { location: }.to_json, headers: json_headers
  end

  context 'when signed in as the owner' do
    before { sign_in owner }

    it 'saves the place and its coordinates' do
      save(place)
      expect(garden.reload).to have_attributes(location: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772)
    end

    it 'leaves the other gardens alone' do
      other = create(:garden, owner:)
      expect { save(place) }.not_to(change { other.reload.location })
    end

    it 'leaves the member\'s own place alone' do
      expect { save(place) }.not_to(change { owner.reload.location })
    end

    it 'refuses coordinates that are not on Earth' do
      save(place.merge(latitude: 120))
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'refuses a place without a name' do
      save(place.merge(name: ''))
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  context 'when signed in as someone else' do
    before { sign_in create(:member) }

    it 'is forbidden' do
      save(place)
      expect(response).to have_http_status(:forbidden)
    end

    it 'does not change the garden' do
      expect { save(place) }.not_to(change { garden.reload.location })
    end
  end

  context 'when signed out' do
    it 'asks to sign in' do
      save(place)
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
