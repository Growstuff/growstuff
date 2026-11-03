# frozen_string_literal: true

require 'rails_helper'

describe 'GET /oauth/client-metadata.json' do
  context 'with a signing key configured' do
    before { allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key) }

    it 'names itself as the client_id' do
      get oauth_client_metadata_path

      expect(response.parsed_body['client_id']).to eq("#{request.base_url}/oauth/client-metadata.json")
    end

    it 'publishes a public key' do
      get oauth_client_metadata_path

      expect(response.parsed_body.dig('jwks', 'keys', 0)).not_to have_key('d')
    end
  end

  context 'without a signing key' do
    it 'is not found' do
      get oauth_client_metadata_path

      expect(response).to have_http_status(:not_found)
    end
  end
end
