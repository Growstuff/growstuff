# frozen_string_literal: true

require 'rails_helper'

# GET /gardens/:slug/edit.json and PATCH /gardens/:slug.json are for our own React
# garden cards only: session cookie and CSRF token, same origin.
describe 'Editing a garden as JSON' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:london_member) }
  let!(:garden) { create(:garden, owner: member, name: 'Orchard', description: 'Apples', area: 12, area_unit: 'square metre') }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def update_garden(attributes, target: garden)
    patch "/gardens/#{target.slug}.json", params: { garden: attributes }.to_json, headers: json_headers
  end

  context 'when signed in' do
    before { sign_in member }

    it 'gives the current values and the choices for the selects' do
      type = create(:garden_type, name: 'Allotment')
      garden.update!(garden_type: type)

      get "/gardens/#{garden.slug}/edit.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response).to have_http_status(:ok)
      body = response.parsed_body
      expect(body['garden']).to include('url' => "/gardens/#{garden.slug}", 'name' => 'Orchard', 'description' => 'Apples',
                                        'area' => '12.0', 'area_unit' => 'square metre', 'garden_type_id' => type.id, 'active' => true)
      expect(body['area_units']).to include('label' => 'hectares', 'value' => 'hectare')
      expect(body['garden_types']).to include('id' => type.id, 'name' => 'Allotment')
      expect(body).to include('member_has_location' => true, 'settings_url' => '/members/edit')
    end

    it "shows the member's location for a garden that has none of its own" do
      garden.update_columns(location: nil)

      get "/gardens/#{garden.slug}/edit.json", headers: { 'ACCEPT' => 'application/json' }

      expect(response.parsed_body.dig('garden', 'location')).to eq 'Greenwich, UK'
    end

    describe "saves the changes and returns the garden's refreshed card" do
      before { update_garden({ name: 'Back orchard', description: 'Apples and pears' }) }

      it { expect(response).to have_http_status(:ok) }
      it { expect(garden.reload).to have_attributes(name: 'Back orchard', description: 'Apples and pears') }
      it { expect(response.parsed_body['garden']).to include('id' => garden.id, 'name' => 'Back orchard', 'active' => true) }
    end

    it 'does not queue a flash message for the next page' do
      update_garden({ name: 'Back orchard' })

      get root_path
      expect(response.body).not_to include(I18n.t('gardens.updated'))
    end

    describe 'marks the garden inactive, finishing its plantings, and says so in the card' do
      let!(:planting) { create(:planting, garden: garden, owner: member) }

      before { update_garden({ active: false }) }

      it { expect(response.parsed_body['garden']).to include('active' => false) }
      it { expect(garden.reload.active).to be false }
      it { expect(planting.reload.finished).to be true }
    end

    describe 'returns validation errors as 422 and keeps the old values' do
      before { update_garden({ name: '' }) }

      it { expect(response).to have_http_status(:unprocessable_entity) }
      it { expect(response.parsed_body['errors']).to have_key('name') }
      it { expect(garden.reload.name).to eq 'Orchard' }
    end

    describe "refuses someone else's garden" do
      let!(:someone_elses) { create(:garden) }

      before { update_garden({ name: 'Mine now' }, target: someone_elses) }

      it { expect(response).to have_http_status(:forbidden) }
      it { expect(someone_elses.reload.name).not_to eq 'Mine now' }
    end
  end

  it 'asks a visitor who is not signed in to sign in' do
    update_garden({ name: 'Nope' })

    expect(response).to have_http_status(:unauthorized)
  end
end
