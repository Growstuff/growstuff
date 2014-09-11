require 'spec_helper'

feature "Planting a crop", :js => true do
  let(:member)   { FactoryGirl.create(:member) }
  let!(:maize)   { FactoryGirl.create(:maize) }

  background do
    login_as(member)
    visit '/plantings/new'
  end

  it_behaves_like "crop suggest", "planting", "crop"

  scenario "Creating a new planting" do
    fill_autocomplete "crop", :with => "m"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      fill_in "When", :with => "2014-06-15"
      fill_in "How many?", :with => 42
      select "cutting", :from => "Planted from:"
      select "semi-shade", :from => "Sun or shade?"
      fill_in "Tell us more about it", :with => "It's rad."
      click_button "Save"
    end

    expect(page).to have_content "Planting was successfully created"
  end

  scenario "Planting from crop page" do
    visit "/crops/maize"
    click_link "Plant this"
    within "form#new_planting" do
      expect(page).to have_selector "input[value='maize']"
      click_button "Save"
    end

    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "maize"
  end

  scenario "Marking a planting as finished", :js => true do
    fill_autocomplete "crop", :with => "m"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      fill_in "When?", :with => '2014-07-01'
      check 'Mark as finished'
      fill_in "Finished date", :with => '2014-08-30'
      click_button "Save"
    end
    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "Finished: August 30, 2014"
  end

  scenario "Marking a planting as finished without a date", :js => true do
    fill_autocomplete "crop", :with => "m"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      check 'Mark as finished'
      click_button "Save"
    end
    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "Finished: Yes (no date specified)"
  end

end

