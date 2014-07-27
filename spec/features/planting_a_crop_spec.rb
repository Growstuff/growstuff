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
      # fill_autocomplete 'crop', with: 'm'
      fill_in 'crop', :with => "m"

      binding.pry

      sleep 1000

      page.execute_script %Q{ $('#crop').trigger('focus') }
      page.execute_script %Q{ $('#crop').trigger('keydown') }
      expect(page).to have_content("maize")
    end
  end

end