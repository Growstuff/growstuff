# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack::Attack', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  before do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  after do
    Rack::Attack.enabled = false
    Rack::Attack.reset!
  end

  describe 'honeypot route /dont-crawl-me' do
    it 'bans an IP for 7 days when hitting /dont-crawl-me' do
      get '/dont-crawl-me', headers: { 'REMOTE_ADDR' => '1.2.3.4' }
      expect(response).to have_http_status(:forbidden)

      # Next request from same IP should be blocked
      get '/community-gardens', headers: { 'REMOTE_ADDR' => '1.2.3.4' }
      expect(response).to have_http_status(:forbidden)

      # Requests from a different IP should be allowed
      get '/community-gardens', headers: { 'REMOTE_ADDR' => '5.6.7.8' }
      expect(response).not_to have_http_status(:forbidden)

      # Fast forward 7 days plus 1 minute
      travel 7.days + 1.minute do
        get '/community-gardens', headers: { 'REMOTE_ADDR' => '1.2.3.4' }
        expect(response).not_to have_http_status(:forbidden)
      end
    end
  end

  describe 'excessive crawling (>500 page requests in a day)' do
    it 'bans an IP for 1 week after 500 requests in a day' do
      ip = '10.0.0.1'

      500.times do
        get '/community-gardens', headers: { 'REMOTE_ADDR' => ip }
        expect(response).not_to have_http_status(:forbidden)
      end

      # 501st request should be banned
      get '/community-gardens', headers: { 'REMOTE_ADDR' => ip }
      expect(response).to have_http_status(:forbidden)

      # Subsequent request should remain banned
      get '/community-gardens', headers: { 'REMOTE_ADDR' => ip }
      expect(response).to have_http_status(:forbidden)

      # Fast forward 1 week plus 1 minute
      travel 7.days + 1.minute do
        get '/community-gardens', headers: { 'REMOTE_ADDR' => ip }
        expect(response).not_to have_http_status(:forbidden)
      end
    end
  end
end
