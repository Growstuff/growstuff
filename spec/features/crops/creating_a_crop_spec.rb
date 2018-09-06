require 'rails_helper'

feature "Crop - " do
  let!(:crop_wrangler) { create :crop_wrangling_member }
  let!(:member) { create :member }

  background do
    login_as member
    visit new_crop_path
  end

  scenario "creating a crop with multiple scientific and alternate name", :js do
    within "form#new_crop" do
      fill_in "crop_name", with: "Philippine flower"
      fill_in "en_wikipedia_url", with: "https://en.wikipedia.org/wiki/Jasminum_sambac"
      click_button "add-sci_name-row"
      fill_in "sci_name[1]", with: "Jasminum sambac 1"
      fill_in "sci_name[2]", with: "Jasminum sambac 2"
      fill_in "alt_name[1]", with: "Sampaguita"
      click_button "add-alt_name-row"
      click_button "add-alt_name-row"
      fill_in "alt_name[2]", with: "Manol"
      click_button "add-alt_name-row"
      fill_in "alt_name[3]", with: "Jazmin"
      fill_in "alt_name[4]", with: "Matsurika"
      fill_in "request_notes", with: "This is the Philippine national flower."
      click_button "Save"
    end

    expect(page).to have_content 'crop was successfully created.'
    expect(page).to have_content "This crop is currently pending approval."
    expect(page).to have_content "Jasminum sambac 2"
    expect(page).to have_content "Matsurika"
  end
end
