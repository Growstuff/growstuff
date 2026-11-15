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

  context "when not signed in" do
    it "does not show an add new crop button" do
      visit search_crops_path(term: "nonexistent")
      expect(page).to have_no_link "Add New Crop"
      expect(page).to have_no_link "adding a new crop"
    end
  end

  context "when signed in as a member" do
    include_context 'signed in member'

    it "shows the add new crop button and link" do
      visit search_crops_path(term: "nonexistent")
      expect(page).to have_link "Add New Crop", href: new_crop_path
      expect(page).to have_link "adding a new crop", href: new_crop_path
    end
  end

  context "when signed in as a crop wrangler" do
    include_context 'signed in crop wrangler'

    it "shows the add new crop button and link" do
      visit search_crops_path(term: "nonexistent")
      expect(page).to have_link "Add New Crop", href: new_crop_path
      expect(page).to have_link "adding a new crop", href: new_crop_path
    end
  end
end
