require 'rails_helper'

feature "request seeds", :js => true do
  context "signed in user" do
    let(:member) { create :member }
    let(:seed) { create :seed }
    let(:tradable_seed) { create :tradable_seed }

    context "acting as requester" do
      background { login_as member }

      scenario "hide request button when not tradable" do
        visit seed_path(seed)
        expect(page).not_to have_link "Request seeds"
      end

      scenario "do invalid requests" do
        visit seed_path(tradable_seed)
        click_link "Request seeds"
        expect(current_path).to eq new_member_seed_trade_path(member.id)
        within "form#new_seed_trade" do
          fill_in :seed_trade_address, with: "P. Sherman. 42 Wallaby Way, Sydney."
          click_button "Send"
        end
        expect(page).to have_content "1 error prohibited this request from being sent:"
        expect(page).to have_content "Message can't be blank"
        within "form#new_seed_trade" do
          fill_in :seed_trade_address, with: ""
          fill_in :seed_trade_message, with: "My message"
          click_button "Send"
        end
        expect(page).to have_content "1 error prohibited this request from being sent:"
        expect(page).to have_content "Address can't be blank"
      end

      scenario "request seeds" do
        visit seed_path(tradable_seed)
        click_link "Request seeds"
        expect(current_path).to eq new_member_seed_trade_path(member.id)
        within "form#new_seed_trade" do
          fill_in :seed_trade_address, with: "P. Sherman. 42 Wallaby Way, Sydney."
          fill_in :seed_trade_message, with: "My message"
          click_button "Send"
        end
        expect(current_path).to eq member_seed_trades_path(:Member)
        expect(page).to have_content "A seed trade request was successfully created."
        expect(page).to have_content "you requested #{tradable_seed.crop.name} seeds from #{tradable_seed.owner.login_name}"
      end
    end

    context "acting as seed owner" do
      let(:seed_trade) { create :seed_trade}

      background { login_as seed_trade.seed.owner }

      scenario "hide request button when seed owner" do
        visit seed_path(seed_trade.seed.id)
        expect(page).not_to have_link "Request seeds"
      end
    end
  end

  context "NOT signed in user" do
    let(:seed_trade) { create :seed_trade}

    scenario "do not request seeds" do
      visit new_member_seed_trade_path(seed_id: seed_trade.seed.id,
      member_id: seed_trade.seed.owner.id)
      expect(current_path).to eq member_session_path
    end
  end

end
