# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OAuth tokens on the API' do # rubocop:disable RSpec/DescribeClass
  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member) }
  let(:token) { create(:oauth_access_token, resource_owner_id: member.id, scopes:) }
  let(:scopes) { 'read write' }
  let(:bearer) { token.plaintext_token }
  let(:headers) do
    { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json', 'Authorization' => "Bearer #{bearer}" }
  end
  let(:params) { { data: { type: 'jobs', id: job.id.to_s, attributes: { description: 'Changed' } } }.to_json }

  describe 'changing something' do
    before { patch "/api/v1/jobs/#{job.id}", params:, headers: }

    context 'with read and write scope' do
      it 'is allowed' do
        expect(response).to have_http_status(:ok)
      end

      it 'changes it' do
        expect(job.reload.description).to eq 'Changed'
      end
    end

    context 'with only read scope' do
      let(:scopes) { 'read' }

      it 'is forbidden' do
        expect(response).to have_http_status(:forbidden)
      end

      it 'says write scope is needed' do
        expect(response.headers['WWW-Authenticate']).to include('insufficient_scope')
      end

      it 'changes nothing' do
        expect(job.reload.description).not_to eq 'Changed'
      end
    end

    context 'when the token has expired' do
      let(:token) { create(:oauth_access_token, resource_owner_id: member.id, expires_in: 60, created_at: 2.hours.ago) }

      it 'is unauthorised' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the token was revoked' do
      let(:token) { create(:oauth_access_token, resource_owner_id: member.id, revoked_at: 1.minute.ago) }

      it 'is unauthorised' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'when the member has been deleted' do
      let(:member) { create(:member, discarded_at: 1.day.ago) }

      it 'is unauthorised' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with a token nobody issued' do
      let(:bearer) { 'not-a-token' }

      it 'is unauthorised' do
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context 'with a token that is someone else\'s' do
      let(:job) { create(:job) }

      it 'is forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'reading' do
    before { get '/api/v1/jobs', headers: }

    it 'is allowed' do
      expect(response).to have_http_status(:ok)
    end
  end

  describe 'the member\'s own API token' do
    let(:bearer) do
      member.regenerate_api_token
      member.api_token.token
    end

    before { patch "/api/v1/jobs/#{job.id}", params:, headers: }

    it 'still works' do
      expect(response).to have_http_status(:ok)
    end
  end
end
