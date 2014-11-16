require 'rails_helper'

feature "Planting a crop", :js => true do
  let!(:garden)   { FactoryGirl.create(:garden) }

  background do
    login_as(garden.owner)
  end

  scenario "View gardens" do
    visit gardens_path
    expect(page).to have_content "Everyone's gardens"
    click_link "View your gardens"
    expect(page).to have_content "#{garden.owner.login_name}'s gardens"
    click_link "View everyone's gardens"
    expect(page).to have_content "Everyone's gardens"
  end

  scenario "Marking a garden as inactive" do
    visit garden_path(garden)
    click_link "Mark as inactive"
    expect(page).to have_content "Garden was successfully updated"
    expect(page).to have_content "This garden is inactive"
    expect(page).to have_content "Mark as active"
    expect(page).not_to have_content "Mark as inactive"
  end

  scenario "Create new garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    expect(page).to have_content "Garden was successfully created"
    expect(page).to have_content "New garden"
  end

  scenario "Edit garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    click_link "Edit garden"
    fill_in "Name", :with => "Different name"
    click_button "Save"
    expect(page).to have_content "Garden was successfully updated"
    expect(page).to have_content "Different name"
  end

  scenario "Delete garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    visit garden_path(Garden.last)
    click_link "Delete garden"
    expect(page).to have_content "Garden was successfully deleted"
    expect(page).to have_content "#{garden.owner}'s gardens"
  end

end
