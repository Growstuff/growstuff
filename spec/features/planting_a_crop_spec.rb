require 'spec_helper'

feature "Planting a crop", :js => true do
  let(:member) { FactoryGirl.create(:member) }
  let!(:maize) { FactoryGirl.create(:maize) }
  let!(:popcorn) { FactoryGirl.create(:popcorn) }
  let!(:pear) { FactoryGirl.create(:pear) }

  background do
    login_as(member)
    visit '/plantings/new'
  end

  scenario "Typing in the crop name displays suggestions" do
    within "form#new_planting" do
      fill_autocomplete "crop", :with => "p"
    end

    expect(page).to have_content("pear")
    expect(page).to have_content("popcorn")

    within "form#new_planting" do
      fill_autocomplete "crop", :with => "pe"
    end

    expect(page).to have_content("pear")
    expect(page).to_not have_content("popcorn")
    expect(page).to have_selector("input#planting_crop_id[value='#{pear.id}']", :visible => false)
  end

  scenario "Creating a new planting", :js => true do
    within "form#new_planting" do
      fill_autocomplete "crop", :with => "m"
    end
    expect(page).to have_content("maize")
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

end