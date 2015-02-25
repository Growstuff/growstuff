require 'rails_helper'
require 'capybara/email/rspec'
require 'pry'

feature "unsubscribe" do
  let(:member) { FactoryGirl.create(:member) }
  let(:notification) { FactoryGirl.create(:notification) }

  background do
    clear_emails
  end

  scenario "from planting reminder mailing list" do
    # verifying the initial subscription status fo the member
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)

    # generate planting reminder email
    Notifier.planting_reminder(member).deliver
    open_email(member.email)

    # clicking 'Unsubscribe' link will unsubscribe the member
    current_email.click_link 'Unsubscribe'
    updated_member = Member.find(member.id) # reload the member
    expect(updated_member.send_planting_reminder).to eq(false)
    expect(updated_member.send_notification_email).to eq(true)
  end

  scenario "from inbox notification mailing list" do
    # verifying the initial subscription status fo the member
    expect(member.send_planting_reminder).to eq(true)
    expect(member.send_notification_email).to eq(true)

    # generate inbox notification email
    notification.recipient = member
    Notifier.notify(notification).deliver
    open_email(member.email)

    # clicking 'Unsubscribe' link will unsubscribe the member
    current_email.click_link 'Unsubscribe'
    updated_member = Member.find(member.id) # reload the member
    expect(updated_member.send_planting_reminder).to eq(true)
    expect(updated_member.send_notification_email).to eq(false)
  end

  scenario "visiting /members/unsubscribe/somestring" do
    visit unsubscribe_member_url('somestring')
  end

  scenario "visiting /members/unsubscribe/" do
    visit unsubscribe_member_url('')
  end

end