# frozen_string_literal: true

require 'rails_helper'

# The page a Flickr connect pop-up (opened from the add photo dialog) ends on.
describe 'GET /authentications/connected' do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }

  before { sign_in member }

  it 'says Flickr is connected once the member has connected it' do
    create(:flickr_authentication, member: member)

    get connected_authentications_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Flickr is connected')
    expect(response.body).to include('window.close()')
  end

  it 'says it was not connected when the member has not' do
    get connected_authentications_path

    expect(response.body).to include('Flickr was not connected')
  end

  it 'is not a full page of the site: no header or footer to look at in a small window' do
    get connected_authentications_path

    expect(response.body).not_to include('page-footer')
  end
end
