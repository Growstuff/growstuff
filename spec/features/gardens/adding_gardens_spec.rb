# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Gardens", :js do
  context 'signed in' do
    include_context 'signed in member'
    before { visit new_garden_path }

    it "has the required fields help text" do
      expect(page).to have_content "* denotes a required field"
    end

    it "displays required and optional fields properly" do
      expect(page).to have_selector ".required", text: "Name"
      expect(page).to have_selector 'textarea#garden_description'
      expect(page).to have_selector 'input#garden_location'
      expect(page).to have_selector 'input#garden_area'
    end

    it "Create new garden" do
      fill_in "Name", with: "New garden"
      click_button "Save"
      expect(page).to have_content "Garden was successfully created"
      expect(page).to have_content "New garden"
    end

    it "Refuse to create new garden with negative area" do
      visit new_garden_path
      fill_in "Name", with: "Negative Garden"
      fill_in "Area", with: -5
      click_button "Save"
      expect(page).not_to have_content "Garden was successfully created"
      expect(page).to have_content "Area must be greater than or equal to 0"
    end
  end
end
