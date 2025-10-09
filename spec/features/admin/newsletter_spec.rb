# frozen_string_literal: true

require 'rails_helper'

describe "newsletter subscribers", :js do
  include_context 'signed in admin'

  let(:subscriber) { create(:newsletter_recipient_member) }

  describe "navigating to newsletter subscribers admin with js" do
    before do
      @subscriber = subscriber
      visit admin_path
      within 'nav#member_admin' do
        click_link "Newsletter subscribers"
      end
    end

    it { expect(page).to have_current_path admin_newsletter_path, ignore_query: true }
    it { expect(page).to have_content @subscriber.email }
  end
end
