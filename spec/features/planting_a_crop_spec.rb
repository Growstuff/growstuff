require 'spec_helper'

feature "Planting a crop", :js => true do
  let(:member) { FactoryGirl.create(:member) }
  let!(:maize) { FactoryGirl.create(:maize) }

  background do
    login_as(member)
    visit '/plantings/new'
  end

  scenario "Typing in the crop name displays suggestions" do
    within "form#new_planting" do
      fill_autocomplete "crop", with: "m"
    end

    expect(page).to have_content("maize")
    select_from_autocomplete("maize")
    expect(page).to have_selector("input#planting_crop_id[value='#{maize.id}']", :visible => false)
  end

end