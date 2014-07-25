require 'spec_helper'

feature "Planting a crop", :js => true do
  let(:wrangler) { FactoryGirl.create(:member) }
  let(:maize) { FactoryGirl.create(:maize) }

  background do
    login_as(wrangler)
    visit '/plantings/new'
  end

  scenario "Typing in the crop name displays suggestions" do
    within "form#new_planting" do
      fill_in "What did you plant?", :with => "m"
      expect(page).to have_content("maize")
    end
  end

end