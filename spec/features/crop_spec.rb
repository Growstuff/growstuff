require 'spec_helper'

feature "Alternate names" do
  let(:alternate_eggplant) { FactoryGirl.create(:alternate_eggplant) }

  scenario "Display alternate names on crop page" do
    visit crop_path(alternate_eggplant.crop)
    expect(page).to have_content alternate_eggplant.name
  end

  context "User is a crop wrangler" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:member){crop_wranglers.first}

    before :each do
      visit root_path
      click_link 'Sign in'
      fill_in 'Login', with: member.login_name
      fill_in 'Password', with: member.password
      click_button 'Sign in'
      page.should have_content member.login_name
    end

    scenario "Crop wranglers can edit alternate names" do
      visit crop_path(alternate_eggplant.crop)
      expect(page).to have_content "CROP WRANGLER"
      expect(page).to have_content alternate_eggplant.name
      expect(page).to have_link "Edit", :href => edit_alternate_name_path(alternate_eggplant)
    end

    scenario "Crop wranglers can delete alternate names" do
      visit crop_path(alternate_eggplant.crop)
      expect(page).to have_link "Delete",
        href: alternate_name_path(alternate_eggplant)
    end

    scenario "Crop wranglers can add alternate names" do
      crop = alternate_eggplant.crop
      visit crop_path(crop)
      expect(page).to have_link "Add",
        href: new_alternate_name_path(crop_id: crop.id)
    end
  end

end
