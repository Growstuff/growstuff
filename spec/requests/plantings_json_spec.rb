# frozen_string_literal: true

require 'rails_helper'

# POST /plantings.json and PATCH /plantings/:slug.json are for our own React garden cards only: session cookie
# and CSRF token, same origin. It is not part of the public API (/api/v1).
describe 'Creating and updating a planting as JSON' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:crop) { create(:annual_crop, name: 'lettuce') }
  let(:json_headers) { { 'CONTENT_TYPE' => 'application/json', 'ACCEPT' => 'application/json' } }

  def create_planting(garden_id: garden.id, crop_id: crop.id, headers: json_headers, **attributes)
    post '/plantings.json', params:  { planting: { garden_id:, crop_id:, quantity: 3, **attributes } }.to_json,
                            headers: headers
  end

  context 'when signed in' do
    before { sign_in member }

    it "creates the planting and returns the garden's updated card" do
      expect { create_planting }.to change { garden.plantings.count }.by(1)

      expect(response).to have_http_status(:created)
      card = response.parsed_body['garden']
      expect(card).to include('id' => garden.id, 'name' => garden.name)
      expect(card['annuals'].map { |planting| planting.dig('crop', 'name') }).to eq ['lettuce']
      expect(garden.plantings.last).to have_attributes(owner: member, crop: crop, quantity: 3)
    end

    it 'does not include the owner in the card, which the page already has' do
      create_planting

      expect(response.parsed_body['garden']['owner']).to be_nil
    end

    it 'defaults the planted date to today' do
      create_planting

      expect(garden.plantings.last.planted_at).to eq Time.zone.today
    end

    it 'returns the validation errors as 422 and creates nothing' do
      expect { create_planting(crop_id: nil) }.not_to(change(Planting, :count))

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('crop')
    end

    it "refuses a garden that is not yours, with a JSON 403 and not a redirect" do
      someone_elses = create(:garden)

      expect { create_planting(garden_id: someone_elses.id) }.not_to(change(Planting, :count))

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body).to have_key('error')
    end

    it 'reports a missing garden as a validation error' do
      create_planting(garden_id: nil)

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body['errors']).to have_key('garden')
    end
  end

  describe 'Loading a planting to edit as JSON' do
    let!(:planting) do
      create(:planting, garden: garden, owner: member, crop: crop, planted_at: Date.new(2026, 3, 1),
                        quantity: 4, sunniness: 'shade', description: 'By the fence')
    end

    it 'gives the current values and the choices for the selects' do
      sign_in member

      get "/plantings/#{planting.slug}/edit.json", headers: json_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body['planting']).to include(
        'url' => "/plantings/#{planting.slug}", 'crop' => { 'id' => crop.id, 'name' => 'lettuce' },
        'planted_at' => '2026-03-01', 'quantity' => 4, 'sunniness' => 'shade',
        'description' => 'By the fence'
      )
      expect(response.parsed_body['planted_from_values']).to include('seed', 'seedling')
      expect(response.parsed_body['sunniness_values']).to eq %w(sun semi-shade shade)
    end

    it "refuses someone else's planting" do
      sign_in create(:member)

      get "/plantings/#{planting.slug}/edit.json", headers: json_headers

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'Updating a planting as JSON' do
    let!(:planting) { create(:planting, garden: garden, owner: member, crop: crop, planted_at: Date.new(2026, 3, 1)) }

    def update_planting(attributes, target: planting)
      patch "/plantings/#{target.slug}.json", params: { planting: attributes }.to_json, headers: json_headers
    end

    context 'when signed in' do
      before { sign_in member }

      it "changes the planted date and returns the garden's updated card" do
        update_planting({ planted_at: '2026-04-15' })

        expect(response).to have_http_status(:ok)
        expect(planting.reload.planted_at).to eq Date.new(2026, 4, 15)
        annual = response.parsed_body.dig('garden', 'annuals').find { |row| row['id'] == planting.id }
        expect(annual['planted_at']).to eq '2026-04-15'
      end

      it 'marks it finished on the date given, and the refreshed card no longer lists it' do
        update_planting({ finished: true, finished_at: '2026-04-15' })

        expect(response).to have_http_status(:ok)
        expect(planting.reload).to have_attributes(finished: true, finished_at: Date.new(2026, 4, 15))
        expect(response.parsed_body.dig('garden', 'annuals').pluck('id')).not_to include(planting.id)
      end

      it 'does not finish it on or before the day it was planted' do
        update_planting({ finished: true, finished_at: '2026-03-01' })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to have_key('finished_at')
        expect(planting.reload.finished).to be false
      end

      it 'returns validation errors as 422 and keeps the old date' do
        planting.update!(finished_at: Date.new(2026, 3, 10))

        update_planting({ planted_at: '2026-05-01' })

        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body['errors']).to have_key('finished_at')
        expect(planting.reload.planted_at).to eq Date.new(2026, 3, 1)
      end

      it "refuses someone else's planting" do
        someone_elses = create(:planting, planted_at: Date.new(2026, 3, 1))

        update_planting({ planted_at: '2026-04-15' }, target: someone_elses)

        expect(response).to have_http_status(:forbidden)
        expect(someone_elses.reload.planted_at).to eq Date.new(2026, 3, 1)
      end
    end

    it 'asks a visitor who is not signed in to sign in' do
      update_planting({ planted_at: '2026-04-15' })

      expect(response).to have_http_status(:unauthorized)
      expect(planting.reload.planted_at).to eq Date.new(2026, 3, 1)
    end
  end

  it 'asks a visitor who is not signed in to sign in' do
    expect { create_planting }.not_to(change(Planting, :count))

    expect(response).to have_http_status(:unauthorized)
  end

  describe 'CSRF protection' do
    # Each controller class copies this setting when it is defined, so it has to
    # be switched on for PlantingsController itself, not just ActionController::Base.
    around do |example|
      original = PlantingsController.allow_forgery_protection
      PlantingsController.allow_forgery_protection = true
      example.run
    ensure
      PlantingsController.allow_forgery_protection = original
    end

    # A real cookie session, as a browser has. (The sign_in test helper bypasses
    # the session, so it can't show what CSRF protection does.)
    before do
      post member_session_path, params: { member: { login: member.email, password: 'password1' } }
    end

    it 'treats a request without the token as signed out, and creates nothing' do
      expect { create_planting }.not_to(change(Planting, :count))

      expect(response).to have_http_status(:unauthorized)
    end

    it 'accepts a request carrying the token from the page' do
      get new_planting_path
      token = Capybara.string(response.body).find('meta[name=csrf-token]', visible: :all)['content']

      expect { create_planting(headers: json_headers.merge('X-CSRF-Token' => token)) }
        .to change { garden.plantings.count }.by(1)
      expect(response).to have_http_status(:created)
    end

    it 'rejects a wrong token' do
      expect { create_planting(headers: json_headers.merge('X-CSRF-Token' => 'not-the-token')) }
        .not_to(change(Planting, :count))

      expect(response).to have_http_status(:unauthorized)
    end
  end

  describe 'cross-origin requests' do
    before { sign_in member }

    it 'get no CORS headers, so other sites cannot call it from a browser' do
      create_planting(headers: json_headers.merge('Origin' => 'https://example.com'))

      expect(response.headers.keys.map(&:downcase)).not_to include('access-control-allow-origin')
    end

    it 'get no CORS headers on a preflight either' do
      process :options, '/plantings.json', headers: { 'Origin'                        => 'https://example.com',
                                                      'Access-Control-Request-Method' => 'POST' }

      expect(response.headers.keys.map(&:downcase)).not_to include('access-control-allow-origin')
    end
  end

  describe 'the new planting form, when arriving from a garden' do
    before { sign_in member }

    it 'does not ask which garden, and posts the one you came from' do
      get new_planting_path(garden_id: garden.id)

      page = Capybara.string(response.body)
      expect(page).to have_css("input[type=hidden][name='planting[garden_id]'][value='#{garden.id}']", visible: :all)
      expect(page).to have_text "Planting in #{garden.name}"
      expect(page).to have_no_text 'Where did you plant it?'
    end

    it 'still asks when it is not from one of your gardens' do
      get new_planting_path(garden_id: create(:garden).id)

      expect(Capybara.string(response.body)).to have_text 'Where did you plant it?'
    end

    it 'still asks when no garden was given' do
      get new_planting_path

      expect(Capybara.string(response.body)).to have_text 'Where did you plant it?'
    end
  end
end
