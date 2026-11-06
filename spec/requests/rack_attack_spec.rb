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

  describe 'cache store' do
    it 'counts requests in process memory, not in Rails.cache' do
      expect(Rack::Attack.cache.store).to be_a(ActiveSupport::Cache::MemoryStore)
      expect(Rack::Attack.cache.store).not_to equal(Rails.cache)
    end

    it 'keeps banning an IP when Rails.cache is broken' do
      allow(Rails.cache).to receive(:increment).and_raise(IOError, 'memcached is down')
      allow(Rails.cache).to receive(:read).and_raise(IOError, 'memcached is down')

      get '/dont-crawl-me', headers: { 'REMOTE_ADDR' => '1.2.3.4' }
      get '/community-gardens', headers: { 'REMOTE_ADDR' => '1.2.3.4' }

      expect(response).to have_http_status(:forbidden)
    end
  end

  describe 'BLOCKED_IPS environment variable' do
    before do
      allow(ENV).to receive(:fetch).and_call_original
      allow(ENV).to receive(:fetch).with('BLOCKED_IPS', '').and_return('9.9.9.9, 8.8.8.8')
    end

    it 'blocks every IP in the list' do
      get '/community-gardens', headers: { 'REMOTE_ADDR' => '9.9.9.9' }
      expect(response).to have_http_status(:forbidden)

      get '/community-gardens', headers: { 'REMOTE_ADDR' => '8.8.8.8' }
      expect(response).to have_http_status(:forbidden)
    end

    it 'allows IPs that are not in the list' do
      get '/community-gardens', headers: { 'REMOTE_ADDR' => '5.6.7.8' }
      expect(response).not_to have_http_status(:forbidden)
    end
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

  describe '.rate_limit_modifier' do
    subject(:modifier) { Rack::Attack.rate_limit_modifier(request) }

    let(:request) { instance_double(Rack::Attack::Request, env: { 'warden' => warden }) }
    let(:warden) { instance_double(Warden::Proxy, user: user) }

    context 'when user is an admin' do
      let(:user) { instance_double(Member, role?: true) }

      it 'returns 0.25' do
        expect(modifier).to eq(0.25)
      end
    end

    context 'when user is logged in' do
      let(:user) { instance_double(Member, role?: false) }

      it 'returns 0.5' do
        expect(modifier).to eq(0.5)
      end
    end

    context 'without an authenticated user' do
      let(:user) { nil }

      it 'returns 1.0' do
        expect(modifier).to eq(1.0)
      end
    end
  end

  describe '.modified_limit' do
    subject(:limit) { Rack::Attack.modified_limit(request, 20) }

    let(:request) { instance_double(Rack::Attack::Request, env: { 'warden' => warden }) }
    let(:warden) { instance_double(Warden::Proxy, user: user) }

    context 'when user is an admin' do
      let(:user) { instance_double(Member, role?: true) }

      it 'scales the limit to 80' do
        expect(limit).to eq(80)
      end
    end

    context 'when user is logged in' do
      let(:user) { instance_double(Member, role?: false) }

      it 'scales the limit to 40' do
        expect(limit).to eq(40)
      end
    end

    context 'without an authenticated user' do
      let(:user) { nil }

      it 'keeps the base limit of 20' do
        expect(limit).to eq(20)
      end
    end
  end

  describe 'throttling restricted routes with rate limit modifier' do
    let(:ip) { '192.168.1.100' }

    context 'without an authenticated user' do
      it 'allows requests up to the 20 request threshold' do
        20.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      it 'throttles requests exceeding the 20 request threshold' do
        20.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        get '/members', headers: { 'REMOTE_ADDR' => ip }
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context 'when user is logged in' do
      let(:member) { create(:member) }

      before { sign_in member }

      it 'allows requests beyond the default threshold up to 40' do
        40.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      it 'throttles requests exceeding 40 requests' do
        40.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        get '/members', headers: { 'REMOTE_ADDR' => ip }
        expect(response).to have_http_status(:too_many_requests)
      end
    end

    context 'when user is an admin' do
      let(:admin) { create(:admin_member) }

      before { sign_in admin }

      it 'allows requests beyond the logged-in threshold up to 80' do
        80.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        expect(response).not_to have_http_status(:too_many_requests)
      end

      it 'throttles requests exceeding 80 requests' do
        80.times { get '/members', headers: { 'REMOTE_ADDR' => ip } }
        get '/members', headers: { 'REMOTE_ADDR' => ip }
        expect(response).to have_http_status(:too_many_requests)
      end
    end
  end
end
