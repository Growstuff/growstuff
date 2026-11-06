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

  it 'renders the notification subject and body' do
    expect(rendered).to include('You have a new notification: Test Notification Subject')
    expect(rendered).to include('Test Notification Body')
  end

  it 'does not include outer html or body tags' do
    expect(rendered).not_to include('<!DOCTYPE html>')
    expect(rendered).not_to include('<html>')
    expect(rendered).not_to include('<body>')
  end
end
