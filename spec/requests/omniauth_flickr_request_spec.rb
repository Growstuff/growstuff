# frozen_string_literal: true

require 'rails_helper'

describe 'Starting a Flickr sign-in' do # rubocop:disable RSpec/DescribeClass
  context 'with POST' do
    before { post '/members/auth/flickr', params: { origin: '/authentications/connected' } }

    it('goes to the callback') { expect(response).to redirect_to('/members/auth/flickr/callback') }
  end

  context 'with GET' do
    it('is not routed') { expect { get '/members/auth/flickr' }.to raise_error(ActionController::RoutingError) }
  end
end
