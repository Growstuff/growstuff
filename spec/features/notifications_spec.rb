require 'rails_helper'

feature "Notifications", :js => true do
  let(:sender) { FactoryGirl.create(:member) }
  let(:recipient) { FactoryGirl.create(:member) }
  
  context "On existing notification" do
    let!(:notification) { FactoryGirl.create(:notification, sender: sender, recipient: recipient, body: "Notification body", :post_id => nil) }

    background do
      login_as(recipient)
      visit notification_path(notification)
    end

    scenario "Replying to the notification" do
      click_link "Reply"
      expect(page).to have_content "Notification body"

      fill_in 'notification_body', with: "Response body"
      click_button "Send"

      expect(page).to have_content "Message was successfully sent"
    end
  end
end