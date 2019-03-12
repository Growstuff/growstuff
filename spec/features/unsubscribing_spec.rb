require 'rails_helper'
require 'capybara/email/rspec'

describe "unsubscribe" do
  let(:member) { create :member }
  let(:notification) { create :notification }

  before { clear_emails }

  describe "from planting reminder mailing list" do
    # verifying the initial subscription status of the member
    it { expect(member.send_planting_reminder).to eq(true) }
    it { expect(member.send_notification_email).to eq(true) }
    
    context 'when i generate planting reminder email' do
      before do
        Notifier.planting_reminder(member).deliver_now
        open_email(member.email)
      end

      context 'and then click 'Unsubscribe' link to unsubscribe the member' do
        before { current_email.click_link 'Unsubscribe from planting reminders' }
        it { expect(page).to have_content "You have been unsubscribed from planting reminders"}
        context 'then reload the member' do
          before { updated_member = Member.find(member.id) }
          it { expect(updated_member.send_planting_reminder).to eq(false) }
          it { expect(updated_member.send_notification_email).to eq(true) }
        end
      end
    end
  end

  it "from inbox notification mailing list" do
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

  describe "visit unsubscribe page with a non-encrypted parameter" do
    # verifying the initial subscription status of the member
    it { expect(member.send_planting_reminder).to eq(true) }
    it { expect(member.send_notification_email).to eq(true) }
    
    context 'visit /members/unsubscribe/somestring ie.parameter to the URL is a random string' do
      before { visit unsubscribe_member_url("type=send_planting_reminder&member_id=#{member.id}") }
      it { expect(page).to have_content "We're sorry, there was an error" }
      it { expect(member.send_planting_reminder).to eq(true) }
      it { expect(member.send_notification_email).to eq(true) }
    end
  end
end
