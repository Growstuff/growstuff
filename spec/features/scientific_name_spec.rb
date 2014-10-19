require 'spec_helper'

feature "Scientific names" do
  let!(:zea_mays) { FactoryGirl.create(:zea_mays) }
  let(:crop) { zea_mays.crop }

  scenario "Display scientific names on crop page" do
    visit crop_path(zea_mays.crop)
    expect(page).to have_content zea_mays.scientific_name
  end

  scenario "Index page for scientific names" do
    visit scientific_names_path
    expect(page).to have_content zea_mays.scientific_name
  end

  context "User is a crop wrangler" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:member){crop_wranglers.first}

    before :each do
      login_as(member)
    end

    scenario "Crop wranglers can edit scientific names" do
      visit crop_path(crop)
      expect(page).to have_content "CROP WRANGLER"
      expect(page).to have_content zea_mays.scientific_name
      expect(page).to have_link "Edit", :href => edit_scientific_name_path(zea_mays)
      within('.scientific_names') { click_on "Edit" }
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Scientific name', with: "Zea mirabila"
      click_on "Save"
      expect(page).to have_content "Zea mirabila"
      expect(page).to have_content 'Scientific name was successfully updated'
    end

    scenario "Crop wranglers can delete scientific names" do
      visit crop_path(zea_mays.crop)
      expect(page).to have_link "Delete",
        href: scientific_name_path(zea_mays)
      within('.scientific_names') { click_on "Delete" }
      expect(page).to_not have_content zea_mays.scientific_name
      expect(page).to have_content 'Scientific name was successfully deleted'
    end

    scenario "Crop wranglers can add scientific names" do
      visit crop_path(crop)
      expect(page).to have_link "Add",
        href: new_scientific_name_path(crop_id: crop.id)
      within('.scientific_names') { click_on "Add" }
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Scientific name', with: "Zea mirabila"
      click_on "Save"
      expect(page).to have_content "Zea mirabila"
      expect(page).to have_content 'Scientific name was successfully created'
    end

    scenario "The show-scientific-name page works" do
      visit scientific_name_path(zea_mays)
      expect(page).to have_link zea_mays.crop.name,
        href: crop_path(zea_mays.crop)
    end

  end

end
