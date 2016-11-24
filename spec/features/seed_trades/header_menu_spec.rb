require 'rails_helper'

feature "request seeds", :js => true do
  context "signed in user" do
    let(:seed_trade) { create :seed_trade }

    scenario "has the correct header to seed_owner" do
      login_as seed_trade.seed.owner
      visit root_path
      expect(page).to have_content("Your Stuff (1)")
    end

    scenario "has the correct header to requester" do
      login_as seed_trade.requester
      visit root_path
      expect(page).not_to have_content("Your Stuff (1)")
    end

  end
end
