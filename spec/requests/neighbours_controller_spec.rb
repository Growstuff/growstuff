# frozen_string_literal: true

require 'rails_helper'

describe NeighboursController do
  let(:member) { create(:member) }
  let(:friend) { create(:member, login_name: 'friendly') }

  before do
    Rails.cache.clear
    member.follows.create!(followed: friend)
    sign_in member
  end

  it 'sends the next small chunk, and where the one after it is' do
    create_list(:planting, Neighbours::FEED_EVENTS + 3, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))

    get neighbours_feed_path(offset: 0, after: nil)
    first = response.parsed_body
    expect(first['html']).to include('friendly')
    expect(first['next']).to eq neighbours_feed_path(scope: 'auto', offset: Neighbours::FEED_EVENTS, after: '2026-10-12')

    get first['next']
    expect(response.parsed_body['next']).to be_nil
  end

  it 'does not repeat the heading of a day that carries on' do
    create(:planting, owner: friend, garden: friend.gardens.first, planted_at: Date.new(2026, 10, 12))

    get neighbours_feed_path(after: '2026-10-12')
    expect(response.parsed_body['html']).not_to include('neighbours-day')
  end

  it 'is not for visitors' do
    sign_out member
    get neighbours_feed_path
    expect(response).to redirect_to(new_member_session_path)
  end
end
