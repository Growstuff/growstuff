require 'rails_helper'

feature "Seeds", :js => true do
  let(:member)   { FactoryGirl.create(:member) }
  let!(:maize)   { FactoryGirl.create(:maize) }

  background do
    login_as(member)
    visit new_seed_path
    sync_elasticsearch([maize])
  end

  it_behaves_like "crop suggest", "seed", "crop"

  scenario "Adding a new seed", :js => true do
    fill_autocomplete "crop", :with => "mai"
    select_from_autocomplete "maize"
    within "form#new_seed" do
      fill_in "Quantity:", :with => 42
      fill_in "Plant before:", :with => "2014-06-15"
      fill_in "Days until maturity:", :with => 999
      fill_in "to", :with => 1999
      select "certified organic", :from => "Organic?"
      select "non-certified GMO-free", :from => "GMO?"
      select "heirloom", :from => "Heirloom?"
      fill_in "Description", :with => "It's killer."
      select "internationally", :from => "Will trade:"
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
