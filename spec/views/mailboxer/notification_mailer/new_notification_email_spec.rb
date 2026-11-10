# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'mailboxer/notification_mailer/new_notification_email.html.erb', type: :view do
  let(:notification) do
    double(
      'Mailboxer::Notification',
      subject: 'Test Notification Subject',
      body: 'Test Notification Body'
    )
  end

  before do
    assign(:notification, notification)
    render
  end

  describe 'renders the notification subject and body' do
    it { expect(rendered).to include('You have a new notification: Test Notification Subject') }
    it { expect(rendered).to include('Test Notification Body') }
  end

  describe 'does not include outer html or body tags' do
    it { expect(rendered).not_to include('<!DOCTYPE html>') }
    it { expect(rendered).not_to include('<html>') }
    it { expect(rendered).not_to include('<body>') }
  end
end
