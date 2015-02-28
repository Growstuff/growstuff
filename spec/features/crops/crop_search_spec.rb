require 'rails_helper'

feature "crop search" do
  scenario "search results show the search term in title" do
    visit root_path
    within "form#navbar-search" do
      fill_in "term", with: "tomato"
      click_button "Search"
    end
    expect(page).to have_css "h1", text: "Crops matching \"tomato\""
  end

  scenario "search page with no search term shows suitable title" do
    visit crops_search_path
    expect(page).to have_css "h1", text: "Crop search"
  end

  scenario "search page has a search form on it" do
    visit crops_search_path
    expect(page).to have_css "form#crop-search"
  end
end
