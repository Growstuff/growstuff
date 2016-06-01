require 'rails_helper'

feature "request seeds", :js => true do
  context "signed in user" do
    let(:member)              { create :member }

    context "acting as requester" do
      background { login_as member }

      scenario "mark as received" do
        sent_seed_trade = FactoryGirl.create(:sent_seed_trade, requester: member)

        visit member_seed_trade_path(sent_seed_trade.requester.id, sent_seed_trade.id)
        click_button "Mark as Received"
        expect(current_path).to eq member_seed_trades_path(sent_seed_trade.requester.id)
        expect(page).to have_content "You have successfully marked this request as received."
      end

    end

    context "acting as seed owner" do

      scenario "accept a request" do
        seed_trade = FactoryGirl.create(:seed_trade, requester: member)

        login_as seed_trade.seed.owner

        visit member_seed_trade_path(seed_trade.seed.owner.id, seed_trade.id)
        click_button "Accept"
        expect(current_path).to eq member_seed_trades_path(seed_trade.seed.owner.id)
        expect(page).to have_content "You have successfully accepted this request."
      end

      scenario "decline a request" do
        seed_trade = FactoryGirl.create(:seed_trade, requester: member)

        login_as seed_trade.seed.owner

        visit member_seed_trade_path(seed_trade.seed.owner.id, seed_trade.id)
        click_button "Decline"
        expect(current_path).to eq member_seed_trades_path(seed_trade.seed.owner.id)
        expect(page).to have_content "You have successfully declined this request."
      end

      scenario "mark as sent" do
        accepted_seed_trade = FactoryGirl.create(:accepted_seed_trade, requester: member)

        login_as accepted_seed_trade.seed.owner

        visit member_seed_trade_path(accepted_seed_trade.seed.owner.id, accepted_seed_trade.id)
        click_button "Mark as Sent"
        expect(current_path).to eq member_seed_trades_path(accepted_seed_trade.seed.owner.id)
        expect(page).to have_content "You have successfully marked this request as sent."
      end

    end

  end
end
