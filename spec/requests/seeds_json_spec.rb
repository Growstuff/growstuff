# frozen_string_literal: true

require 'rails_helper'

# GET /plantings/:slug/seeds/new.json and POST /seeds.json are for our own React
# garden cards only: session cookie and CSRF token, same origin.
describe 'Saving seeds as JSON' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:london_member) }
  let(:garden) { create(:garden, owner: member) }
  let(:crop) { create(:annual_crop, name: 'lettuce') }
  let!(:planting) { create(:planting, garden: garden, owner: member, crop: crop) }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def save_seeds(**attributes)
    post '/seeds.json', params:  { seed: { parent_planting_id: planting.id, saved_at: '2026-09-21', quantity: 40,
                                           tradable_to: 'locally', description: 'Bolted early', **attributes } }.to_json,
                        headers: json_headers
  end

  describe 'loading the form' do
    before { sign_in member }

    it 'gives the crop, the trade choices and where the member is' do
      get "/plantings/#{planting.slug}/seeds/new.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body).to include(
        'crop' => { 'id' => crop.id, 'name' => 'lettuce' }, 'parent_planting_id' => planting.id,
        'tradable_to_values' => %w(nowhere locally nationally internationally),
        'location' => 'Greenwich, UK', 'settings_url' => '/members/edit'
      )
      expect(response.parsed_body['saved_at']).to eq Time.zone.today.to_s
    end

    it 'has no location when the member has not set one' do
      member.update_columns(location: nil)

      get "/plantings/#{planting.slug}/seeds/new.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response.parsed_body['location']).to be_nil
    end
  end

  context 'when signed in' do
    before { sign_in member }

    it 'saves the seeds from the planting and returns a link to them' do
      expect { save_seeds }.to change { planting.child_seeds.count }.by(1)

      expect(response).to have_http_status(:created)
      seed = planting.child_seeds.last
      expect(response.parsed_body['seed']).to eq('id' => seed.id, 'url' => "/seeds/#{seed.slug}")
      expect(seed).to have_attributes(owner: member, crop: crop, quantity: 40, tradable_to: 'locally',
                                      description: 'Bolted early', source: 'my own seed saving', saved_at: Date.new(2026, 9, 21))
    end

    it 'does not queue a flash message for the next page' do
      save_seeds

      get root_path
      expect(response.body).not_to include('to your stash')
    end

    it 'takes seeds with no quantity or notes' do
      expect { save_seeds(quantity: '', description: '', tradable_to: 'nowhere') }.to change(Seed, :count).by(1)

      expect(Seed.last).to have_attributes(quantity: nil, tradable_to: 'nowhere')
    end

    it 'returns the validation errors as 422 and saves nothing' do
      expect { save_seeds(tradable_to: 'the moon') }.not_to(change(Seed, :count))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('tradable_to')
    end
  end

  it 'asks a visitor who is not signed in to sign in' do
    expect { save_seeds }.not_to(change(Seed, :count))

    expect(response).to have_http_status(:unauthorized)
  end
end
