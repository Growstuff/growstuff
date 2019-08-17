require 'rails_helper'

describe "Notifications", :js do
  let(:sender)    { create :member                        }
  let(:recipient) { create :member, login_name: 'beyonce' }

  include_context 'signed in member' do
    let(:member) { recipient }

    context "On existing notification" do
      let!(:notification) do
        create :notification,
               sender:    sender,
               recipient: recipient,
               body:      "Notification body",
               post_id:   nil
      end
      before do
        visit root_path
        click_link 'Your Stuff'
        Percy.snapshot(page, name: "notification menu")
        visit notification_path(notification)
        Percy.snapshot(page, name: "notifications#show")
      end

      it "Replying to the notification" do
        click_link "Reply"
        expect(page).to have_content "Notification body"
        Percy.snapshot(page, name: 'Replying to notification')

        fill_in 'notification_body', with: "Response body"
        Percy.snapshot(page, name: "notifications#new")
        click_button "Send"

        expect(page).to have_content "Message was successfully sent"
      end
    end

    describe 'pagination' do
      before do
        FactoryBot.create_list :notification, 34, recipient: recipient
        visit notifications_path
      end

      it do
        Percy.snapshot(page, name: "notifications#index")
      end

      it 'has page navigation' do
        expect(page).to have_selector 'a[rel="next"]'
      end

      it 'paginates at 30 notifications per page' do
        expect(page).to have_selector '.message', count: 30
      end

      it 'navigates pages' do
        first('a[rel="next"]').click
        expect(page).to have_selector '.message', count: 4
      end
    end
  end
end
