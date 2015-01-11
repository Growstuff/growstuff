require 'rails_helper'

feature "Harvesting a crop", :js => true do
  let(:member)   { FactoryGirl.create(:member) }
  let!(:maize)   { FactoryGirl.create(:maize) }

  background do
    login_as(member)
    visit new_seed_path
  end

  it_behaves_like "crop suggest", "seed", "crop"

  scenario "Adding a new seed", :js => true do
    fill_autocomplete "crop", :with => "m"
    select_from_autocomplete "maize"
    within "form#new_seed" do
      fill_in "Quantity:", :with => 42
      fill_in "Plant before:", :with => "2014-06-15"
      fill_in "Description", :with => "It's killer."
      select "internationally", :from => "Will trade:"
      click_button "Save"
    end

    expect(page).to have_content "Successfully added maize seed to your stash"
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
