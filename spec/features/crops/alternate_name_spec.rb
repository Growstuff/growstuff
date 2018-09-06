require 'rails_helper'

feature "Alternate names", js: true do
  let!(:alternate_eggplant) { create :alternate_eggplant }
  let(:crop) { alternate_eggplant.crop }

  scenario "Display alternate names on crop page" do
    visit crop_path(alternate_eggplant.crop)
    expect(page.status_code).to equal 200
    expect(page).to have_content alternate_eggplant.name
  end

  scenario "Index page for alternate names" do
    visit alternate_names_path
    expect(page).to have_content alternate_eggplant.name
  end

  context "User is a crop wrangler" do
    let!(:crop_wranglers) { create_list :crop_wrangling_member, 3 }
    let(:member) { crop_wranglers.first }

    background do
      login_as member
    end

    scenario "Crop wranglers can edit alternate names" do
      visit crop_path(crop)
      expect(page.status_code).to equal 200
      expect(page).to have_content "CROP WRANGLER"
      expect(page).to have_content alternate_eggplant.name
      expect(page).to have_link "Edit", href: edit_alternate_name_path(alternate_eggplant)
      within('.alternate_names') { click_on "Edit" }
      expect(page.status_code).to equal 200
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "alternative aubergine"
      click_on "Save"
      expect(page.status_code).to equal 200
      expect(page).to have_content "alternative aubergine"
      expect(page).to have_content 'Alternate name was successfully updated'
    end

    scenario "Crop wranglers can delete alternate names" do
      visit crop_path(alternate_eggplant.crop)
      expect(page).to have_link "Delete",
        href: alternate_name_path(alternate_eggplant)
      within('.alternate_names') { click_on "Delete" }
      expect(page.status_code).to equal 200
      expect(page).not_to have_content alternate_eggplant.name
      expect(page).to have_content 'Alternate name was successfully deleted'
    end

    scenario "Crop wranglers can add alternate names" do
      visit crop_path(crop)
      expect(page).to have_link "Add",
        href: new_alternate_name_path(crop_id: crop.id)
      within('.alternate_names') { click_on "Add" }
      expect(page.status_code).to equal 200
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "not an aubergine"
      click_on "Save"
      expect(page.status_code).to equal 200
      expect(page).to have_content "not an aubergine"
      expect(page).to have_content 'Alternate name was successfully created'
    end

    scenario "The show-alternate-name page works" do
      visit alternate_name_path(alternate_eggplant)
      expect(page.status_code).to equal 200
      expect(page).to have_content alternate_eggplant.crop.name
    end

    context "When alternate name is rejected" do
      let(:rejected_crop) { create :rejected_crop }
      let(:pending_alt_name) { create :alternate_name, crop: rejected_crop }

      scenario "Displays crop rejection message" do
        visit alternate_name_path(pending_alt_name)
        expect(page).to have_content "This crop was rejected for the following reason: Totally fake"
      end
    end
  end
end
