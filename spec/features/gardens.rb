require 'spec_helper'

feature "Planting a crop", :js => true do
  let!(:garden)   { FactoryGirl.create(:garden) }

  background do
    login_as(garden.owner)
    visit garden_path(garden)
  end

  scenario "Marking a garden as inactive" do
    click_link "Mark as inactive"
    expect(page).to have_content "Garden was successfully updated"
    expect(page).to have_content "This garden is inactive"
    expect(page).to have_content "Mark as active"
    expect(page).not_to have_content "Mark as inactive"
  end

end
