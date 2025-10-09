# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Gardens", :js do
  context 'signed in' do
    include_context 'signed in member'
    before { visit new_garden_path }

    include_examples 'is accessible'

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
  end
end
