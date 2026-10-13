# frozen_string_literal: true

require 'rails_helper'

describe 'The old timeline', type: :request do
  it 'is now the friends and neighbours page' do
    get '/timeline'
    expect(response).to redirect_to('/my/neighbours')
  end
end
