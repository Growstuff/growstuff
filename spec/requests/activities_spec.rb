# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Activities requests' do
  let(:member) { create(:member) }

  describe 'GET /my/activities' do
    context 'when not authenticated' do
      it 'redirects to sign in' do
        get my_activities_path
        expect(response).to redirect_to(new_member_session_path)
      end
    end

    context 'when authenticated' do
      before { sign_in member }

      it 'returns 200 OK and renders my activities' do
        activity = create(:activity, owner: member, name: 'Weeding garden')
        get my_activities_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('My Activities Board')
        expect(response.body).to include('Weeding garden')
      end
    end
  end

  describe 'PATCH /activities/:slug.json' do
    let!(:activity) { create(:activity, owner: member, status: 'planned') }

    before { sign_in member }

    it 'updates status via JSON request' do
      patch activity_path(activity, format: :json), params: { activity: { status: 'in_progress' } }
      expect(response).to have_http_status(:ok)

      activity.reload
      expect(activity.status).to eq('in_progress')
      expect(activity.finished).to be false
    end

    it 'updates status to done and marks finished as true' do
      patch activity_path(activity, format: :json), params: { activity: { status: 'done' } }
      expect(response).to have_http_status(:ok)

      activity.reload
      expect(activity.status).to eq('done')
      expect(activity.finished).to be true
    end
  end
end
