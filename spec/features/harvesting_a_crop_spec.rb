require 'spec_helper'

feature "Harvesting a crop", :js => true do
  let(:member)   { FactoryGirl.create(:member) }
  let!(:maize)   { FactoryGirl.create(:maize) }

  background do
    login_as(member)
    visit '/harvests/new'
  end

  it_behaves_like "crop suggest", "harvest", "crop"

  scenario "Creating a new harvest", :js => true do
    fill_autocomplete "crop", :with => "m"
    select_from_autocomplete "maize"
    within "form#new_harvest" do
      fill_in "When?", :with => "2014-06-15"
      fill_in "How many?", :with => 42
      fill_in "Weighing (in total):", :with => 42
      fill_in "Notes", :with => "It's killer."
      click_button "Save"
    end

    expect(page).to have_content "Harvest was successfully created"
  end

end