require 'rails_helper'
require 'custom_matchers'

feature "Gardens", :js do
  let(:member) { FactoryBot.create :member }

  background do
    login_as member
    visit new_garden_path
  end

  it "has the required fields help text" do
    expect(page).to have_content "* denotes a required field"
  end

  it "displays required and optional fields properly" do
    expect(page).to have_selector ".form-group.required", text: "Name"
    expect(page).to have_optional 'textarea#garden_description'
    expect(page).to have_optional 'input#garden_location'
    expect(page).to have_optional 'input#garden_area'
  end

  scenario "Create new garden" do
    fill_in "Name", with: "New garden"
    click_button "Save"
    expect(page).to have_content "Garden was successfully created"
    expect(page).to have_content "New garden"
  end

  scenario "Refuse to create new garden with negative area" do
    visit new_garden_path
    fill_in "Name", with: "Negative Garden"
    fill_in "Area", with: -5
    click_button "Save"
    expect(page).not_to have_content "Garden was successfully created"
    expect(page).to have_content "Area must be greater than or equal to 0"
  end
end
