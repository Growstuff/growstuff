# frozen_string_literal: true

require 'rails_helper'

describe "Scientific names", :js do
  let!(:zea_mays) { create(:zea_mays) }
  let(:crop)      { zea_mays.crop }

  it "Display scientific names on crop page" do
    visit crop_path(zea_mays.crop)
    # expect(page.status_code).to equal 200
    expect(page).to have_content zea_mays.name
  end

  it "Index page for scientific names" do
    visit scientific_names_path
    # expect(page.status_code).to equal 200
    expect(page).to have_content zea_mays.name
  end

  context "User is a crop wrangler" do
    let!(:crop_wranglers) { create_list(:crop_wrangling_member, 3) }

    include_context 'signed in crop wrangler'
    it "Crop wranglers can edit scientific names" do
      visit crop_path(crop)
      # expect(page.status_code).to equal 200
      expect(page).to have_content zea_mays.name
      # Each name has its own menu; editing opens a dialog over the page.
      click_link zea_mays.name
      within('.scientific_names') { click_on "Edit" }
      within('[role=dialog]') do
        fill_in 'Scientific name', with: "Zea mirabila"
        click_on "Save"
      end
      expect(page).to have_content "Zea mirabila"
      expect(page).to have_content 'crop was successfully updated'
    end

    it "Crop wranglers can delete scientific names" do
      visit crop_path(zea_mays.crop)
      click_link zea_mays.name
      expect(page).to have_link "Delete",
                                href: scientific_name_path(zea_mays)
      within('.scientific_names') do
        accept_confirm do
          click_link 'Delete'
        end
      end
      # expect(page.status_code).to equal 200
      expect(page).to have_no_content zea_mays.name
      expect(page).to have_content 'Scientific name was successfully deleted.'
    end

    it "Crop wranglers can add scientific names" do
      visit crop_path(crop)
      # Adding is an item in the crop's actions menu, which opens a dialog.
      click_link 'Actions'
      click_on "Add scientific name"
      # The dialog knows which crop it is for, so there is no crop to choose.
      within('[role=dialog]') do
        fill_in 'Scientific name', with: "Zea mirabila"
        click_on "Save"
      end
      expect(page).to have_content "Zea mirabila"
      expect(page).to have_content 'crop was successfully created.'
    end

    it "The show-scientific-name page works" do
      visit scientific_name_path(zea_mays)
      # expect(page.status_code).to equal 200
      expect(page).to have_link zea_mays.crop.name,
                                href: crop_path(zea_mays.crop)
    end

    context "When scientific name is pending" do
      let(:pending_crop) { create(:crop_request) }
      let(:pending_sci_name) { create(:scientific_name, crop: pending_crop) }

      it "Displays crop pending message" do
        visit scientific_name_path(pending_sci_name)
        expect(page).to have_content "This crop is currently pending approval"
      end
    end
  end
end
