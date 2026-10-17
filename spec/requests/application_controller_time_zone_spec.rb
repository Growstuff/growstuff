# frozen_string_literal: true

require 'rails_helper'

# The server works in UTC, but a member's today is the day in their own time zone.
describe ApplicationController do
  include ActiveSupport::Testing::TimeHelpers

  let(:member) { create(:member) }
  let(:nursery) { member.nursery! }

  # 21:00 UTC on the 17th is already the morning of the 18th in Auckland.
  before do
    travel_to(Time.utc(2026, 10, 17, 21, 0, 0))
    sign_in member
    create(:planting, owner: member, garden: nursery, planted_at: Date.new(2026, 10, 17))
  end

  context 'with a time zone cookie' do
    before { get member_gardens_path(member), headers: { 'Cookie' => 'timezone=Pacific/Auckland' } }

    it 'says the 17th was yesterday' do
      expect(response.body).to include 'yesterday'
    end
  end

  context 'without one' do
    before { get member_gardens_path(member) }

    it 'says the 17th is today, in UTC' do
      expect(response.body).to include 'Today'
    end
  end

  context 'with a time zone we do not know' do
    before { get member_gardens_path(member), headers: { 'Cookie' => 'timezone=Nowhere/Land' } }

    it 'falls back to UTC' do
      expect(response.body).to include 'Today'
    end
  end
end
