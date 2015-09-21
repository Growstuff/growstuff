require 'rails_helper'

feature "request seeds", :js => true do
  context "signed in user" do
    let(:member)              { create :member }

    after :each do
      expect(page).to have_content "Message:"
      expect(page).to have_content "Adress to send:"
    end

    context "acting as requester" do
      background { login_as member }

      after :each do
        expect(page).not_to have_button "Accept"
        expect(page).not_to have_button "Decline"
        expect(page).not_to have_button "Mark as Sent"
      end


      scenario "open a seed request just created" do
        seed_trade = FactoryGirl.create(:seed_trade, requester: member)

        visit member_seed_trades_path(seed_trade.requester.id)
        click_link "you requested #{seed_trade.seed.crop.name} seeds from #{seed_trade.seed.owner.login_name}"
        expect(current_path).to eq member_seed_trade_path(seed_trade.requester.id, seed_trade.id)
        expect(page).not_to have_button "Mark as Received"

        expect(page).to have_content seed_trade.message
        expect(page).to have_content seed_trade.address
      end

      scenario "open an accepted seed trade request" do
        accepted_seed_trade = FactoryGirl.create(:accepted_seed_trade, requester: member)

        visit member_seed_trades_path(accepted_seed_trade.requester.id)
        click_link "you requested #{accepted_seed_trade.seed.crop.name} seeds from #{accepted_seed_trade.seed.owner.login_name}"
        expect(current_path).to eq member_seed_trade_path(accepted_seed_trade.requester.id, accepted_seed_trade.id)
        expect(page).not_to have_button "Mark as Received"

        expect(page).to have_content accepted_seed_trade.message
        expect(page).to have_content accepted_seed_trade.address
      end

      scenario "open a declined seed trade request" do
        declined_seed_trade = FactoryGirl.create(:declined_seed_trade, requester: member)

        visit member_seed_trades_path(declined_seed_trade.requester.id)
        click_link "you requested #{declined_seed_trade.seed.crop.name} seeds from #{declined_seed_trade.seed.owner.login_name}"
        expect(current_path).to eq member_seed_trade_path(declined_seed_trade.requester.id, declined_seed_trade.id)
        expect(page).not_to have_button "Mark as Received"

        expect(page).to have_content declined_seed_trade.message
        expect(page).to have_content declined_seed_trade.address
      end

      scenario "open a seed trade marked as 'sent'" do
        sent_seed_trade = FactoryGirl.create(:sent_seed_trade, requester: member)

        visit member_seed_trades_path(sent_seed_trade.requester.id)
        click_link "you requested #{sent_seed_trade.seed.crop.name} seeds from #{sent_seed_trade.seed.owner.login_name}"
        expect(current_path).to eq member_seed_trade_path(sent_seed_trade.requester.id, sent_seed_trade.id)
        expect(page).to have_button "Mark as Received"

        expect(page).to have_content sent_seed_trade.message
        expect(page).to have_content sent_seed_trade.address
      end

      scenario "open a seed trade marked as 'received'" do
        received_seed_trade = FactoryGirl.create(:received_seed_trade, requester: member)

        visit member_seed_trades_path(received_seed_trade.requester.id)
        click_link "you requested #{received_seed_trade.seed.crop.name} seeds from #{received_seed_trade.seed.owner.login_name}"
        expect(current_path).to eq member_seed_trade_path(received_seed_trade.requester.id, received_seed_trade.id)
        expect(page).not_to have_button "Mark as Received"

        expect(page).to have_content received_seed_trade.message
        expect(page).to have_content received_seed_trade.address
      end

    end

    context "acting as seed owner" do

      after :each do
        expect(page).not_to have_button "Mark as Received"
      end

      scenario "open a seed request just created" do
        seed_trade = FactoryGirl.create(:seed_trade, requester: member)

        login_as seed_trade.seed.owner

        visit member_seed_trades_path(seed_trade.seed.owner.id)
        requester = seed_trade.requester.login_name
        crop_name = seed_trade.seed.crop.name

        click_link "#{requester} has requested #{crop_name} seeds from you"
        expect(current_path).to eq member_seed_trade_path(seed_trade.seed.owner.id, seed_trade.id)
        expect(page).to have_button "Accept"
        expect(page).to have_button "Decline"
        expect(page).not_to have_button "Mark as Sent"


        expect(page).to have_content seed_trade.message
        expect(page).to have_content seed_trade.address
      end

      scenario "open an accepted seed trade request" do
        accepted_seed_trade = FactoryGirl.create(:accepted_seed_trade, requester: member)

        login_as accepted_seed_trade.seed.owner

        visit member_seed_trades_path(accepted_seed_trade.seed.owner.id)
        requester = accepted_seed_trade.requester.login_name
        crop_name = accepted_seed_trade.seed.crop.name

        click_link "#{requester} has requested #{crop_name} seeds from you"
        expect(current_path).to eq member_seed_trade_path(accepted_seed_trade.seed.owner.id, accepted_seed_trade.id)
        expect(page).not_to have_button "Accept"
        expect(page).not_to have_button "Decline"
        expect(page).to have_button "Mark as Sent"

        expect(page).to have_content accepted_seed_trade.message
        expect(page).to have_content accepted_seed_trade.address
      end

      scenario "open a declined seed trade request" do
        declined_seed_trade = FactoryGirl.create(:declined_seed_trade, requester: member)

        login_as declined_seed_trade.seed.owner

        visit member_seed_trades_path(declined_seed_trade.seed.owner.id)
        requester = declined_seed_trade.requester.login_name
        crop_name = declined_seed_trade.seed.crop.name

        click_link "#{requester} has requested #{crop_name} seeds from you"
        expect(current_path).to eq member_seed_trade_path(declined_seed_trade.seed.owner.id, declined_seed_trade.id)
        expect(page).not_to have_button "Accept"
        expect(page).not_to have_button "Decline"
        expect(page).not_to have_button "Mark as Sent"

        expect(page).to have_content declined_seed_trade.message
        expect(page).to have_content declined_seed_trade.address
      end

      scenario "open a sent seed trade request" do
        sent_seed_trade = FactoryGirl.create(:sent_seed_trade, requester: member)

        login_as sent_seed_trade.seed.owner

        visit member_seed_trades_path(sent_seed_trade.seed.owner.id)
        requester = sent_seed_trade.requester.login_name
        crop_name = sent_seed_trade.seed.crop.name

        click_link "#{requester} has requested #{crop_name} seeds from you"
        expect(current_path).to eq member_seed_trade_path(sent_seed_trade.seed.owner.id, sent_seed_trade.id)
        expect(page).not_to have_button "Accept"
        expect(page).not_to have_button "Decline"
        expect(page).not_to have_button "Mark as Sent"

        expect(page).to have_content sent_seed_trade.message
        expect(page).to have_content sent_seed_trade.address
      end

      scenario "open a received seed trade request" do
        received_seed_trade = FactoryGirl.create(:received_seed_trade, requester: member)

        login_as received_seed_trade.seed.owner

        visit member_seed_trades_path(received_seed_trade.seed.owner.id)
        requester = received_seed_trade.requester.login_name
        crop_name = received_seed_trade.seed.crop.name

        click_link "#{requester} has requested #{crop_name} seeds from you"
        expect(current_path).to eq member_seed_trade_path(received_seed_trade.seed.owner.id, received_seed_trade.id)
        expect(page).not_to have_button "Accept"
        expect(page).not_to have_button "Decline"
        expect(page).not_to have_button "Mark as Sent"

        expect(page).to have_content received_seed_trade.message
        expect(page).to have_content received_seed_trade.address
      end

    end

  end
end
