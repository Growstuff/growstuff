# frozen_string_literal: true

require 'rails_helper'

describe 'Unsubscribing from emails' do
  let(:member) { create(:member) }
  let(:verifier) { ActiveSupport::MessageVerifier.new(ENV.fetch('RAILS_SECRET_TOKEN', nil)) }

  def link_in(mail, text)
    Nokogiri::HTML(mail.body.encoded).css('a').find { |anchor| anchor.text.include?(text) }['href']
  end

  def unsubscribe_via(mail, text)
    get URI(link_in(mail, text)).request_uri
  end

  context 'with the link in the planting reminder' do
    before { unsubscribe_via(NotifierMailer.planting_reminder(member), 'Unsubscribe from planting reminders') }

    it { expect(response).to have_http_status(:ok) }
    it { expect(response.body).to include 'unsubscribed from planting reminders' }
    it { expect(member.reload.send_planting_reminder).to be false }
    it { expect(member.reload.send_harvest_reminder).to be true }
    it { expect(member.reload.send_notification_email).to be true }
  end

  context 'with the link in the harvest reminder' do
    let(:crop) { create(:crop, median_days_to_first_harvest: 20) }

    before do
      create(:planting, owner: member, crop:, planted_at: 15.days.ago)
      unsubscribe_via(NotifierMailer.harvest_reminder(member), 'Unsubscribe from harvest reminders')
    end

    it { expect(member.reload.send_harvest_reminder).to be false }
    it { expect(member.reload.send_planting_reminder).to be true }
  end

  context 'with a signed message for a column that is not an email setting' do
    before { get unsubscribe_member_path(verifier.generate({ member_id: member.id, type: :email })) }

    it { expect(response.body).to include 'there was an error' }
    it { expect(member.reload.email).to eq member.email }
  end

  context 'with a message that was not signed by us' do
    before { get unsubscribe_member_path('not-signed') }

    it { expect(response.body).to include 'there was an error' }
  end
end
