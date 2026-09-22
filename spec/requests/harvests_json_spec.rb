# frozen_string_literal: true

require 'rails_helper'

# GET /plantings/:slug/harvests/new.json and POST /harvests.json are for our own
# React garden cards only: session cookie and CSRF token, same origin.
describe 'Recording a harvest as JSON' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:crop) { create(:annual_crop, name: 'lettuce') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: crop, planted_at: Date.new(2026, 3, 1)) }
  let(:leaf) { create(:plant_part, name: 'leaf') }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def record_harvest(target: planting, **attributes)
    post '/harvests.json', params:  { harvest: { planting_id: target.id, plant_part_id: leaf.id, harvested_at: '2026-06-01',
                                                 quantity: 3, unit: 'individual', **attributes } }.to_json,
                           headers: json_headers
  end

  describe 'loading the form' do
    before { sign_in member }

    it 'gives the crop, the choices, and the plant part it is usually harvested for' do
      create(:harvest, crop: crop, plant_part: leaf)
      create(:plant_part, name: 'seed')

      get "/plantings/#{planting.slug}/harvests/new.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:ok)
      form = response.parsed_body
      expect(form).to include('crop' => { 'id' => crop.id, 'name' => 'lettuce' }, 'planting_id' => planting.id,
                              'plant_part_id' => leaf.id)
      expect(form['plant_parts'].pluck('name')).to include('leaf', 'seed')
      expect(form['units']).to include('label' => 'bunches', 'value' => 'bunch')
      expect(form['weight_units'].pluck('value')).to eq %w(kg lb oz)
    end

    it 'has no plant part chosen when the crop has never been harvested' do
      get "/plantings/#{planting.slug}/harvests/new.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response.parsed_body['plant_part_id']).to be_nil
    end
  end

  context 'when signed in' do
    before { sign_in member }

    it "records the harvest and returns the garden's updated card" do
      expect { record_harvest }.to change { planting.harvests.count }.by(1)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig('garden', 'id')).to eq garden.id
      expect(planting.harvests.last).to have_attributes(owner: member, crop: crop, plant_part: leaf, quantity: 3)
    end

    it 'returns the validation errors as 422 and records nothing' do
      expect { record_harvest(plant_part_id: nil) }.not_to(change(Harvest, :count))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('plant_part')
    end

    it "does not record a harvest on someone else's planting" do
      someone_elses = create(:planting)

      expect { record_harvest(target: someone_elses) }.not_to(change(Harvest, :count))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('owner')
    end
  end

  it 'asks a visitor who is not signed in to sign in' do
    expect { record_harvest }.not_to(change(Harvest, :count))

    expect(response).to have_http_status(:unauthorized)
  end
end
