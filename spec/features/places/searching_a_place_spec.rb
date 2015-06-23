require "rails_helper"

RSpec.feature "User searches", :type => :feature do
	
	scenario "with a valid place" do
		visit "/places"
		search_with("Philippines")
		assert true
	end

	scenario "with a blank search string" do
		visit "/places"
		search_with("")
		assert true
	end

	def search_with(search_string)
		fill_in "new_place", :with => search_string
		click_button "search_button"
	end

end