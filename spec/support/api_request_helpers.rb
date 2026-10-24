# frozen_string_literal: true

# Headers, a member holding an API token, and the parsed response body for specs of /api/v1.
RSpec.shared_context 'with an API member' do
  let(:member) { create(:member) }
  let(:token) do
    member.regenerate_api_token
    member.api_token.token
  end
  let(:read_headers) { { 'Accept' => 'application/vnd.api+json' } }
  let(:write_headers) { read_headers.merge('Content-Type' => 'application/vnd.api+json') }
  let(:auth_headers) { write_headers.merge('Authorization' => "Bearer #{token}") }

  # Not a memoised let: specs that make several requests need the body of the latest.
  def json
    JSON.parse(response.body)
  end

  # The ids of the resources in the response.
  def ids
    json['data'].pluck('id')
  end
end

module ApiLinkHelpers
  # How a resource links to what it is related to.
  def related_link(path)
    { 'links' => { 'related' => "http://www.example.com/api/v1/#{path}" } }
  end
end

RSpec.configure do |config|
  config.include ApiLinkHelpers, file_path: %r{spec/requests/api}
end
