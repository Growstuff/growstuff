# frozen_string_literal: true

RSpec.shared_context 'with authenticated member' do
  let(:member) { create(:member) }
  let(:api_token) { member.regenerate_api_token }
  let(:headers) do
    {
      'Accept' => 'application/vnd.api+json',
      'Authorization' => "Token token=#{api_token.token}",
      'Content-Type' => 'application/vnd.api+json'
    }
  end
  let(:unauthenticated_headers) do
    {
      'Accept' => 'application/vnd.api+json',
      'Content-Type' => 'application/vnd.api+json'
    }
  end
end