require 'rails_helper'

describe "Requesting a new crop" do
  context "As a regular member" do
    let(:member)    { create :member                }
    let!(:wrangler) { create :crop_wrangling_member }

    before do
      login_as member
    end

    it "Submit request" do
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
    let!(:crop)             { create :crop_request }
    let!(:already_approved) { create :crop         }

    before { login_as wrangler }

    it "Approve a request" do
      visit edit_crop_path(crop)
      select "approved", from: "Approval status"
      click_button "Save"
      expect(page).to have_content "En wikipedia url is not a valid English Wikipedia URL"
      fill_in "en_wikipedia_url", with: "http://en.wikipedia.org/wiki/Aung_San_Suu_Kyi"
      click_button "Save"
      expect(page).to have_content "crop was successfully updated."
    end

    it "Rejecting a crop" do
      visit edit_crop_path(crop)
      select "rejected", from: "Approval status"
      select "not edible", from: "Reason for rejection"
      click_button "Save"
      expect(page).to have_content "crop was successfully updated."
    end
  end
end
