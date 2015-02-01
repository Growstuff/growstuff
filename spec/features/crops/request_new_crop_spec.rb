require 'rails_helper'

feature "Requesting a new crop" do

  context "As a regular member" do

    let(:member) { FactoryGirl.create(:member) }

    before { login_as member }

    scenario "Submit request" do
      visit new_crop_path
      fill_in "Name", with: "Couch potato"
      fill_in "Comments", with: "Couch are real for real."
      click_button "Save"
      expect(page).to have_content "Crop was successfully requested."
    end

  end

  context "As a crop wrangler" do

    let(:wrangler) { FactoryGirl.create(:crop_wrangling_member) }
    let!(:crop) { FactoryGirl.create(:crop_request) }

    before { login_as wrangler }

    scenario "View pending crops" do
      visit wrangle_crops_path
      within "#requested-crops" do
        expect(page).to have_content "Ultra berry"
      end
      click_link "Ultra berry"
      expect(page).to have_content "This crop is currently pending approval."
      expect(page).to have_content "Please approve this even though it's fake."
    end

    scenario "Approve a request" do
      visit edit_crop_path(crop)
      select "approved", from: "Approval Status"
      click_button "Save"
      expect(page).to have_content "En wikipedia url is not a valid English Wikipedia URL"
      fill_in "Wikipedia URL", with: "http://en.wikipedia.org/wiki/Aung_San_Suu_Kyi"
      click_button "Save"
      expect(page).to have_content "Crop was successfully updated."
    end

    scenario "Rejecting a crop" do
      visit edit_crop_path(crop)
      select "rejected", from: "Approval Status"
      click_button "Save"
      expect(page).to have_content "Crop was successfully updated."
    end

  end

end