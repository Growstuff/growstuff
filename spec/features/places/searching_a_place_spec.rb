require "rails_helper"

RSpec.feature "User searches", :type => :feature do
	
	scenario "with a valid place" do
		visit places_path
		search_with("Philippines")
		expect(page).to have_content "members near Philippines"
		expect(page).to have_button "search_button"
		page.has_content?('placesmap')
		expect(page).to have_content "Nearby members"
	end

	scenario "with a blank search string" do
		visit places_path
		search_with("")
		expect(page).to have_content "Please enter a valid location"
		expect(page).to have_button "search_button"
		page.has_content?('placesmap')
	end

	def search_with(search_string)
		fill_in "new_place", :with => search_string
		click_button "search_button"
	end

end