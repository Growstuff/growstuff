# frozen_string_literal: true

require 'rails_helper'

describe Admin::ReminderStatsController do
  let(:admin) { create(:admin_member) }
  let(:page) { Capybara.string(response.body) }

  context 'with an admin' do
    before do
      create(:member, send_planting_reminder: false, confirmed_at: 1.day.ago)
      create(:reminder_event, kind: 'planting_reminder', event: 'sent', created_at: Time.zone.now)
      create(:reminder_event, kind: 'planting_reminder', event: 'unsubscribed', created_at: Time.zone.now)
      create(:reminder_event, kind: 'harvest_reminder', event: 'sent', created_at: Time.zone.now)
      sign_in admin
      get admin_reminder_stats_path
    end

    it { expect(response).to have_http_status(:ok) }
    it { expect(page).to have_css('#planting_reminder .sent', text: '1', count: 1) }
    it { expect(page).to have_css('#planting_reminder .unsubscribed', text: '1', count: 1) }
    it { expect(page).to have_css('#harvest_reminder .sent', text: '1', count: 1) }
    it { expect(page).to have_no_css('#harvest_reminder .unsubscribed', text: '1') }
    it { expect(page).to have_css('#planting_reminder .opted-out', text: '1') }
    it { expect(page).to have_css('#planting_reminder .badge', text: 'Off') }
  end

  context 'with a member who is not an admin' do
    before do
      sign_in create(:member)
      get admin_reminder_stats_path
    end

    it { expect(response).not_to have_http_status(:ok) }
  end

  context 'without signing in' do
    before { get admin_reminder_stats_path }

    it { expect(response).to redirect_to new_member_session_path }
  end
end
