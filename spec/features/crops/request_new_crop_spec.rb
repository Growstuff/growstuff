require 'rails_helper'

feature "Requesting a new crop" do
  context "As a regular member" do
    let(:member) { create :member }
    let!(:wrangler) { create :crop_wrangling_member }

    background do
      login_as member
    end

    scenario "Submit request" do
      visit new_crop_path
      fill_in "Name", with: "Couch potato"
      fill_in "request_notes", with: "Couch potatoes are real for real."
      click_button "Save"
      expect(page).to have_content 'crop was successfully created.'
      expect(page).to have_content "This crop is currently pending approval."
    end
  end

  context "As a crop wrangler" do
    let(:wrangler) { create :crop_wrangling_member }
    let!(:crop) { create :crop_request }
    let!(:already_approved) { create :crop }

    background { login_as wrangler }

    scenario "Approve a request" do
      visit edit_crop_path(crop)
      select "approved", from: "Approval status"
      click_button "Save"
      expect(page).to have_content "En wikipedia url is not a valid English Wikipedia URL"
      fill_in "en_wikipedia_url", with: "http://en.wikipedia.org/wiki/Aung_San_Suu_Kyi"
      click_button "Save"
      expect(page).to have_content "crop was successfully updated."
    end

    scenario "Rejecting a crop" do
      visit edit_crop_path(crop)
      select "rejected", from: "Approval status"
      select "not edible", from: "Reason for rejection"
      click_button "Save"
      expect(page).to have_content "crop was successfully updated."
    end
  end
end
