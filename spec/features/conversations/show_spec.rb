# frozen_string_literal: true

require 'rails_helper'

describe "Conversations", :js do
  let(:sender)    { create :member                        }
  let(:recipient) { create :member, login_name: 'beyonce' }

  before do
    sender.send_message(recipient, "this is the body", "something i want to say")
    login_as recipient
  end

  describe 'view conversation thread' do
    before do
      visit root_path
      click_link recipient.login_name
      click_link 'Inbox'
      click_link 'something i want to say'
    end

    it { expect(page).to have_content 'this is the body' }
    it { expect(page).to have_link sender.login_name }
    it { Percy.snapshot(page, name: 'conversations#show') }

    describe 'Replying to the conversation' do
      before do
        fill_in :body, with: 'i like this too'
        click_button 'Send'
      end
      it { expect(page).to have_content "i like this too" }
    end
  end
end
