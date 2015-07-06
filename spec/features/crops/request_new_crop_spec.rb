require 'rails_helper'

feature "Requesting a new crop" do

  context "As a regular member" do

    let(:member) { FactoryGirl.create(:member) }
    let!(:wrangler) { FactoryGirl.create(:crop_wrangling_member) }

    background do
      login_as member
    end

    scenario "Submit request" do
      visit new_crop_path
      fill_in "Name", with: "Couch potato"
      fill_in "Comments", with: "Couch potatoes are real for real."
      click_button "Save"
      expect(page).to have_content "Crop was successfully requested."
    end

  end

  context "As a crop wrangler" do

    let(:wrangler) { FactoryGirl.create(:crop_wrangling_member) }
    let!(:crop) { FactoryGirl.create(:crop_request) }
    let!(:already_approved) { FactoryGirl.create(:crop) }

    background do
     login_as wrangler
    end

    scenario "Approve a request" do
      visit edit_crop_path(crop)
      select "approved", from: "Approval status"
      click_button "Save"
      expect(page).to have_content "En wikipedia url is not a valid English Wikipedia URL"
      fill_in "Wikipedia URL", with: "http://en.wikipedia.org/wiki/Aung_San_Suu_Kyi"
      click_button "Save"
      expect(page).to have_content "Crop was successfully updated."
    end

    scenario "Rejecting a crop" do
      visit edit_crop_path(crop)
      select "rejected", from: "Approval status"
      select "not edible", from: "Reason for rejection"
      click_button "Save"
      expect(page).to have_content "Crop was successfully updated."
    end

  end

end
