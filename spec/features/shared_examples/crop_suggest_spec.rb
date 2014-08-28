require 'spec_helper'

shared_examples "crop suggest" do |resource|
  let!(:popcorn) { FactoryGirl.create(:popcorn) }
  let!(:pear)    { FactoryGirl.create(:pear) }
  let!(:tomato)  { FactoryGirl.create(:tomato) }
  let!(:roma)    { FactoryGirl.create(:roma) }

  scenario "Typing in the crop name displays suggestions" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "p"
    end

    expect(page).to have_content("pear")
    expect(page).to have_content("popcorn")

    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "pear"
    end

    expect(page).to have_content("pear")
    expect(page).to_not have_content("popcorn")

    select_from_autocomplete("pear")

    expect(page).to have_selector("input##{resource}_crop_id[value='#{pear.id}']", :visible => false)
  end

  scenario "Typing and pausing does not affect input" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "p"
    end

    expect(page).to have_content("pear")
    expect(find_field("crop").value).to eq("p")
  end

  scenario "Searching for a crop casts a wide net on results" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "to"
    end

    expect(page).to have_content("tomato")
    expect(page).to have_content("roma tomato")
  end

  scenario "Submitting a crop that doesn't exist in the database produces a meaningful error" do
    within "form#new_#{resource}" do
      fill_autocomplete "crop", :with => "Ryan Gosling"
      click_button "Save"
    end

    expect(page).to have_content("Crop must be present and exist in our database")
  end

end