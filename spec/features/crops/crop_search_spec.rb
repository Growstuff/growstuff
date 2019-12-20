# frozen_string_literal: true

require 'rails_helper'

describe "crop search" do
  it "search results show the search term in title" do
    visit root_path
    within "form#navbar-search" do
      fill_in "term", with: "tomato"
      click_button "Search"
    end
    expect(page).to have_css "h1", text: "Crops matching \"tomato\""
  end

  it "search page with no search term shows suitable title" do
    visit search_crops_path
    expect(page).to have_css "h1", text: "Crop search"
  end

  it "search page has a search form on it" do
    visit search_crops_path
    expect(page).to have_css "form#crop-search"
  end
end
