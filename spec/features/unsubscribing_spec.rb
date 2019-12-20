# frozen_string_literal: true

require 'rails_helper'
require 'capybara/email/rspec'

describe "unsubscribe" do
  let(:member)       { create :member       }
  let(:notification) { create :notification }

  before { clear_emails }

  # TODO: get these working again with chrome headless
  pending "from planting reminder mailing list" do
    # verifying the initial subscription status of the member
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)

    # generate planting reminder email
    Notifier.planting_reminder(member).deliver_now
    open_email(member.email)

    # clicking 'Unsubscribe' link will unsubscribe the member
    current_email.click_link 'Unsubscribe from planting reminders'
    expect(page).to have_content "You have been unsubscribed from planting reminders"
    updated_member = Member.find(member.id) # reload the member
    expect(updated_member.send_planting_reminder).to eq(false)
    expect(updated_member.send_notification_email).to eq(true)
  end

  # TODO: get these working again with chrome headless
  pending "from inbox notification mailing list" do
    # verifying the initial subscription status of the member
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)

    # generate inbox notification email
    notification.recipient = member
    Notifier.notify(notification).deliver_now
    open_email(member.email)

    # clicking 'Unsubscribe' link will unsubscribe the member
    current_email.click_link 'Unsubscribe from direct message notifications'
    expect(page).to have_content "You have been unsubscribed from direct message notifications"
    updated_member = Member.find(member.id) # reload the member
    expect(updated_member.send_planting_reminder).to eq(true)
    expect(updated_member.send_notification_email).to eq(false)
  end

  it "visit unsubscribe page with a non-encrypted parameter" do
    # verifying the initial subscription status of the member
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)

    # visit /members/unsubscribe/somestring ie.parameter to the URL is a random string
    visit unsubscribe_member_path("type=send_planting_reminder&member_id=#{member.id}")
    expect(page).to have_content "We're sorry, there was an error"
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)
  end
end
