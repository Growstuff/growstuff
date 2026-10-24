# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Signing an app in with OAuth' do # rubocop:disable RSpec/DescribeClass
  let(:member) { create(:member) }
  let(:client) { create(:oauth_application) }
  let(:verifier) { SecureRandom.urlsafe_base64(48) }
  let(:challenge) { Base64.urlsafe_encode64(Digest::SHA256.digest(verifier), padding: false) }
  let(:authorize_params) do
    { client_id: client.uid, redirect_uri: client.redirect_uri, response_type: 'code', scope: 'read write',
      code_challenge: challenge, code_challenge_method: 'S256' }
  end

  # What the last request answered with. Not memoised, as there can be several.
  def token_json
    response.parsed_body
  end

  # The code the app is sent back with, once the member has said yes.
  def code_for(params = authorize_params)
    post '/oauth/authorize', params: params
    Rack::Utils.parse_query(URI(response.location).query)['code']
  end

  def exchange(code, code_verifier: verifier)
    post '/oauth/token', params: { grant_type: 'authorization_code', code:, client_id: client.uid,
                                     redirect_uri: client.redirect_uri, code_verifier: }
  end

  context 'when the member is not signed in' do
    before { get '/oauth/authorize', params: authorize_params }

    it 'sends them to sign in first' do
      expect(response.location).to include('/members/sign_in')
    end
  end

  context 'when the member is signed in' do
    before { sign_in member }

    describe 'asking' do
      before { get '/oauth/authorize', params: authorize_params }

      it 'asks whether to allow the app' do
        expect(response.body).to include(client.name)
      end
    end

    describe 'allowing' do
      before { post '/oauth/authorize', params: authorize_params }

      it 'sends them back to the app' do
        expect(response.location).to start_with(client.redirect_uri)
      end

      it 'with a code' do
        expect(Rack::Utils.parse_query(URI(response.location).query)).to include('code')
      end
    end

    describe 'trading the code for a token' do
      before { exchange(code_for) }

      it 'gives an access token' do
        expect(token_json).to include('access_token', 'token_type' => 'Bearer', 'scope' => 'read write')
      end

      it 'gives a refresh token' do
        expect(token_json).to include('refresh_token')
      end

      it 'gives a token that expires in an hour' do
        expect(token_json['expires_in']).to eq 3600
      end

      it 'gives a token for the member' do
        expect(Doorkeeper::AccessToken.by_token(token_json['access_token']).resource_owner_id).to eq member.id
      end
    end

    describe 'trading the code with the wrong verifier' do
      before { exchange(code_for, code_verifier: SecureRandom.urlsafe_base64(48)) }

      it 'is refused' do
        expect(response).to have_http_status(:bad_request)
      end

      it 'gives no token' do
        expect(token_json).not_to include('access_token')
      end
    end

    describe 'trading the code without a verifier' do
      before { exchange(code_for, code_verifier: nil) }

      it 'is refused' do
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe 'asking without a challenge' do
      before { get '/oauth/authorize', params: authorize_params.except(:code_challenge, :code_challenge_method) }

      it 'is refused' do
        expect(response).to have_http_status(:bad_request)
      end
    end

    describe 'refreshing' do
      let(:first) { exchange(code_for) && token_json }

      before do
        post '/oauth/token', params: { grant_type: 'refresh_token', refresh_token: first['refresh_token'], client_id: client.uid }
      end

      it 'gives a new access token' do
        expect(token_json['access_token']).not_to eq first['access_token']
      end

      it 'gives a new refresh token each time' do
        expect(token_json['refresh_token']).not_to eq first['refresh_token']
      end
    end

    describe 'signing out' do
      let(:token) { exchange(code_for) && token_json['access_token'] }
      let(:job) { create(:job, owner: member) }
      let(:headers) do
        { 'Accept' => 'application/vnd.api+json', 'Content-Type' => 'application/vnd.api+json', 'Authorization' => "Bearer #{token}" }
      end
      let(:params) { { data: { type: 'jobs', id: job.id.to_s, attributes: { description: 'Changed' } } }.to_json }

      before do
        token
        post '/oauth/revoke', params: { token:, client_id: client.uid }
      end

      it 'is accepted' do
        expect(response).to have_http_status(:ok)
      end

      it 'ends the token\'s use on the API' do
        patch "/api/v1/jobs/#{job.id}", params:, headers: headers
        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe 'managing which apps there are' do
    before do
      sign_in person
      get '/oauth/applications'
    end

    context 'with an admin' do
      let(:person) { create(:admin_member) }

      it 'shows the apps' do
        expect(response).to have_http_status(:ok)
      end
    end

    context 'with an ordinary member' do
      let(:person) { create(:member) }

      it 'is forbidden' do
        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe 'a member being removed' do
    before { create(:oauth_access_token, resource_owner_id: member.id) }

    it 'removes the tokens apps were given for them' do
      expect { member.destroy }.to change(Doorkeeper::AccessToken, :count).by(-1)
    end
  end
end
