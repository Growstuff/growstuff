require 'rails_helper'
require 'custom_matchers'

feature "Seeds", :js, :elasticsearch do
  let(:member) { create :member }
  let!(:maize) { create :maize }

  background do
    login_as member
    visit new_seed_path
    sync_elasticsearch [maize]
  end

  it_behaves_like "crop suggest", "seed", "crop"

  it "has the required fields help text" do
    expect(page).to have_content "* denotes a required field"
  end

  it "displays required and optional fields properly" do
    expect(page).to have_selector ".form-group.required", text: "Crop:"
    expect(page).to have_optional 'input#seed_quantity'
    expect(page).to have_optional 'input#seed_plant_before'
    expect(page).to have_optional 'input#seed_days_until_maturity_min'
    expect(page).to have_optional 'input#seed_days_until_maturity_max'
    expect(page).to have_selector '.form-group.required', text: 'Organic?'
    expect(page).to have_selector '.form-group.required', text: 'GMO?'
    expect(page).to have_selector '.form-group.required', text: 'Heirloom?'
    expect(page).to have_optional 'textarea#seed_description'
    expect(page).to have_selector '.form-group.required', text: 'Will trade:'
  end

  scenario "Adding a new seed", js: true do
    fill_autocomplete "crop", with: "mai"
    select_from_autocomplete "maize"
    within "form#new_seed" do
      fill_in "Quantity:", with: 42
      fill_in "Plant before:", with: "2014-06-15"
      fill_in "Days until maturity:", with: 999
      fill_in "to", with: 1999
      select "certified organic", from: "Organic?"
      select "non-certified GMO-free", from: "GMO?"
      select "heirloom", from: "Heirloom?"
      fill_in "Description", with: "It's killer."
      select "internationally", from: "Will trade:"
      click_button "Save"
    end

    expect(page).to have_content "Successfully added maize seed to your stash"
    expect(page).to have_content "Quantity: 42"
    expect(page).to have_content "Days until maturity: 999–1999"
    expect(page).to have_content "certified organic"
    expect(page).to have_content "non-certified GMO-free"
    expect(page).to have_content "Heirloom? heirloom"
    expect(page).to have_content "It's killer."
  end

  scenario "Adding a seed from crop page" do
    visit crop_path(maize)
    click_link "Add seeds to stash"
    within "form#new_seed" do
      expect(page).to have_selector "input[value='maize']"
      click_button "Save"
    end

    expect(page).to have_content "Successfully added maize seed to your stash"
    expect(page).to have_content "maize"
  end
end
