# frozen_string_literal: true

require 'rails_helper'

describe "Conversations", :js do
  let(:sender)    { create :member                        }
  let(:recipient) { create :member, login_name: 'beyonce' }

  before do
    sender.send_message(recipient, "this is the body", "something i want to say")
    login_as recipient
  end

  describe "Read conversations list" do
    before do
      visit root_path
      click_link recipient.login_name
      click_link 'Inbox'
    end
    it { expect(page).to have_content 'something i want to say' }
    it { Percy.snapshot(page, name: 'conversations#index') }

    describe 'deleting' do
      before do
        check 'conversation_ids[]'
        click_button 'Delete Selected'
      end

      describe 'view trash' do
        before { click_link 'trash' }
        it { expect(page).to have_content 'something i want to say' }
        describe 'restore conversation' do
          before { click_link class: 'restore' }
          it { expect(page).not_to have_content 'something i want to say' }

          describe 'conversation was restored' do
            before { click_link 'inbox' }
            it { expect(page).to have_content 'something i want to say' }
          end
        end
      end
    end
  end

  describe 'deleting conversations' do
    it 'deletes multiple conversations from the inbox' do
      sender.send_message(recipient, 'this is a message', 'message 1')
      sender.send_message(recipient, 'this is another message', 'follow up message')

      visit root_path
      click_link recipient.login_name
      click_link 'Inbox'

      all('input[type=checkbox]').each(&:click)
      click_button 'Delete Selected'

      expect(page).not_to have_content 'this is a message'
      expect(page).not_to have_content 'this is another message'
    end

    it 'deletes multiple conversations from the sentbox' do
      sender.send_message(recipient, 'this is a message', 'message 1')
      sender.send_message(recipient, 'this is another message', 'follow up message')

      visit root_path
      click_link recipient.login_name
      click_link 'Inbox'

      expect(page).to have_selector('.sent')
      find('.sent').click

      all('input[type=checkbox]').each(&:click)
      click_button 'Delete Selected'

      expect(page).to have_selector('.sent')
      find('.sent').click
      expect(page).not_to have_content 'this is a message'
      expect(page).not_to have_content 'this is another message'
    end
  end
end
