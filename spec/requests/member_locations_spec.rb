# frozen_string_literal: true

require 'rails_helper'

# The dialog on the home page that asks where someone gardens: it looks places
# up with GET /places/suggest and saves the one they pick with PATCH /my/location.
describe 'Setting where a member gardens' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }
  let(:place) { { name: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772 } }

  def save(location)
    patch member_location_path(format: :json), params: { location: }.to_json, headers: json_headers
  end

  context 'when signed in' do
    before { sign_in member }

    it 'saves the place and its coordinates' do
      save(place)
      expect(member.reload).to have_attributes(location: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772)
    end

    it 'gives gardens without a place the same one' do
      member.gardens.first.update_columns(location: nil)
      save(place)
      expect(member.gardens.first.reload.location).to eq 'Wellington, New Zealand'
    end

    it 'leaves a garden that already has a place alone' do
      member.gardens.first.update_columns(location: 'Dunedin')
      save(place)
      expect(member.gardens.first.reload.location).to eq 'Dunedin'
    end

    it 'refuses coordinates that are not on Earth' do
      save(place.merge(latitude: 120))
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'refuses a place without a name' do
      save(place.merge(name: ''))
      expect(response).to have_http_status(:unprocessable_entity)
    end

    it 'suggests places for a search' do
      Geocoder::Lookup::Test.add_stub('Wellington',
                                      [{ 'coordinates' => [-41.2887, 174.7772], 'name' => 'Wellington',
'address' => { 'country' => 'New Zealand' } }])
      get suggest_places_path(format: :json, q: 'Wellington')
      expect(response.parsed_body.pluck('name')).to eq ['Wellington, New Zealand']
    end

    it 'suggests nothing for a position that is not a number' do
      get suggest_places_path(format: :json, lat: 'north', lng: 'east')
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe 'clearing it' do
    before do
      member.update_columns(location: 'Wellington, New Zealand', latitude: -41.2887, longitude: 174.7772) # rubocop:disable Rails/SkipsModelValidations
      sign_in member
    end

    it 'removes the place and its coordinates' do
      delete member_location_path
      expect(member.reload).to have_attributes(location: nil, latitude: nil, longitude: nil)
    end

    it 'removes it from the profile form\'s Remove button' do
      post member_location_path, params: { _method: 'delete' }
      expect(member.reload.location).to be_nil
    end

    it 'goes back to the profile form' do
      delete member_location_path
      expect(response).to redirect_to(edit_member_registration_path)
    end
  end

  context 'when signed out' do
    it 'does not save a place' do
      save(place)
      expect(response).to have_http_status(:unauthorized)
    end

    it 'does not look places up' do
      get suggest_places_path(format: :json, q: 'Wellington')
      expect(response).to have_http_status(:unauthorized)
    end
  end
end
