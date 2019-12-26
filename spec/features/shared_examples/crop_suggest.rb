# frozen_string_literal: true

require 'rails_helper'

shared_examples "crop suggest" do |resource|
  let!(:pea)    { create :crop, name: 'pea' }
  let!(:pear)   { create :pear              }
  let!(:tomato) { create :tomato            }
  let!(:roma)   { create :roma              }

  scenario "placeholder text in crop auto suggest field" do
    expect(page).to have_selector("input[placeholder='e.g. lettuce']")
  end

  scenario "typing in the crop name displays suggestions" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "pe"
    end

    expect(page).not_to have_content("pear")
    expect(page).not_to have_content("pea")

    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "pea"
    end

    expect(page).to have_content("pear")
    expect(page).to have_content("pea")

    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "pear"
    end

    expect(page).to have_content("pear")
  end

  scenario "selecting crop from dropdown" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "pear"
    end

    select_from_autocomplete("pear")

    expect(page).to have_selector("input##{resource}_crop_id[value='#{pear.id}']", visible: false)
  end

  scenario "Typing and pausing does not affect input" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "pea"
    end

    expect(page).to have_content("pear")
    expect(find_field("crop").value).to eq("pea")
  end

  scenario "Searching for a crop casts a wide net on results" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "tom"
    end

    expect(page).to have_content("tomato")
    expect(page).to have_content("roma tomato")
  end

  scenario "Submitting a crop that doesn't exist in the database produces a meaningful error" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", with: "Ryan Gosling"
      click_button "Save"
    end

    expect(page).to have_content("Crop must be present and exist in our database")
  end
end
