require 'spec_helper'

feature "Alternate names" do
  let!(:alternate_eggplant) { FactoryGirl.create(:alternate_eggplant) }
  let(:crop) { alternate_eggplant.crop }

  scenario "Display alternate names on crop page" do
    visit crop_path(alternate_eggplant.crop)
    expect(page).to have_content alternate_eggplant.name
  end

  scenario "Index page for alternate names" do
    visit alternate_names_path
    expect(page).to have_content alternate_eggplant.name
  end

  context "User is a crop wrangler" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:member){crop_wranglers.first}

    before :each do
      login_as(member)
    end

    scenario "Crop wranglers can edit alternate names" do
      visit crop_path(crop)
      expect(page).to have_content "CROP WRANGLER"
      expect(page).to have_content alternate_eggplant.name
      expect(page).to have_link "Edit", :href => edit_alternate_name_path(alternate_eggplant)
      within('.alternate_names') { click_on "Edit" }
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "alternative aubergine"
      click_on "Save"
      expect(page).to have_content "alternative aubergine"
    end

    scenario "Crop wranglers can delete alternate names" do
      visit crop_path(alternate_eggplant.crop)
      expect(page).to have_link "Delete",
        href: alternate_name_path(alternate_eggplant)
    end

    scenario "Crop wranglers can add alternate names" do
      visit crop_path(crop)
      expect(page).to have_link "Add",
        href: new_alternate_name_path(crop_id: crop.id)
    end

    scenario "The show-alternate-name page works" do
      visit alternate_name_path(alternate_eggplant)
      expect(page).to have_content alternate_eggplant.crop.name
    end

    scenario "The add-alternate-name page works" do
      visit new_alternate_name_path(crop_id: crop.id)
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "not an aubergine"
      click_on "Save"
      expect(page).to have_content "not an aubergine"
    end

  end

end
