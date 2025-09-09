# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Plantings API Write Operations', type: :request do
  let(:member) { create(:member) }
  let(:token) { member.regenerate_api_token; member.api_token.token }
  let(:headers) { { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json' } }
  let(:auth_headers) { headers.merge('Authorization' => "Token token=#{token}") }

  let(:garden) { create(:garden, owner: member) }
  let(:crop) { create(:crop) }

  let(:planting_params) do
    {
      data: {
        type: 'plantings',
        attributes: {
          description: 'A new planting'
        },
        relationships: {
          garden: { data: { type: 'gardens', id: garden.id } },
          crop: { data: { type: 'crops', id: crop.id } }
        }
      }
    }.to_json
  end

  describe 'POST /api/v1/plantings' do
    it 'returns 401 Unauthorized without a token' do
      post '/api/v1/plantings', params: planting_params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 201 Created with a valid token' do
      post '/api/v1/plantings', params: planting_params, headers: auth_headers
      expect(response).to have_http_status(:created)
      expect(member.plantings.count).to eq(1)
    end
  end

  describe 'PATCH /api/v1/plantings/:id' do
    let(:planting) { create(:planting, owner: member, garden: garden, crop: crop) }
    let(:other_member_planting) { create(:planting) }

    let(:update_params) do
      {
        data: {
          type: 'plantings',
          id: planting.id.to_s,
          attributes: {
            description: 'An updated planting'
          }
        }
      }.to_json
    end

    it 'returns 401 Unauthorized without a token' do
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 200 OK with a valid token for own planting' do
      patch "/api/v1/plantings/#{planting.id}", params: update_params, headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(planting.reload.description).to eq('An updated planting')
    end

    it 'returns 403 Forbidden for another member\'s planting' do
      update_params_for_other = {
        data: {
          type: 'plantings',
          id: other_member_planting.id.to_s,
          attributes: {
            description: 'An updated planting'
          }
        }
      }.to_json
      patch "/api/v1/plantings/#{other_member_planting.id}", params: update_params_for_other, headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'DELETE /api/v1/plantings/:id' do
    let!(:planting) { create(:planting, owner: member, garden: garden, crop: crop) }
    let(:other_member_planting) { create(:planting) }

    it 'returns 401 Unauthorized without a token' do
      delete "/api/v1/plantings/#{planting.id}", headers: headers
      expect(response).to have_http_status(:unauthorized)
    end

    it 'returns 204 No Content with a valid token for own planting' do
      delete "/api/v1/plantings/#{planting.id}", headers: auth_headers
      expect(response).to have_http_status(:no_content)
      expect(Planting.find_by(id: planting.id)).to be_nil
    end

    it 'returns 403 Forbidden for another member\'s planting' do
      delete "/api/v1/plantings/#{other_member_planting.id}", headers: auth_headers
      expect(response).to have_http_status(:forbidden)
    end
  end
end
