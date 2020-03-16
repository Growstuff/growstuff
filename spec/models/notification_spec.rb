# frozen_string_literal: true

require 'rails_helper'

describe Notification do
  let(:notification) { FactoryBot.create(:notification) }

  it "belongs to a post" do
    expect(notification.post).to be_an_instance_of Post
  end

  it "belongs to a recipient" do
    expect(notification.recipient).to be_an_instance_of Member
  end

  it "belongs to a sender" do
    expect(notification.sender).to be_an_instance_of Member
  end

  it "has a scope for unread" do
    expect(described_class.unread).to eq [notification]
    @n2 = FactoryBot.create(:notification, read: true)
    expect(described_class.unread).to eq [notification]
    @n3 = FactoryBot.create(:notification, read: false)
    expect(described_class.unread).to include @n3
    expect(described_class.unread).to include notification
  end

  it "sends email if asked" do
    @notification2 = FactoryBot.create(:notification)
    @notification2.send_message
    expect(ActionMailer::Base.deliveries.last&.to).to eq [@notification2.recipient.email]
  end

  it "doesn't send email to people who don't want it" do
    FactoryBot.create(:no_email_notification).send_message
    expect(ActionMailer::Base.deliveries.last&.to).not_to eq [notification.recipient.email]
  end

  it "sends email on creation" do
    @notification2 = FactoryBot.create(:notification)
    expect(ActionMailer::Base.deliveries.last&.to).to eq [@notification2.recipient.email]
  end

  it "replaces missing subjects with (no subject)" do
    notification = FactoryBot.create(:notification, subject: nil)
    expect(notification.subject).to eq "(no subject)"
  end

  it "replaces whitespace-only subjects with (no subject)" do
    notification = FactoryBot.create(:notification, subject: "    ")
    expect(notification.subject).to eq "(no subject)"
  end
end
