require 'rails_helper'

feature "crop wranglers" do
  context "signed in wrangler" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:wrangler){crop_wranglers.first}
    let!(:crops) { FactoryGirl.create_list(:crop, 2) }

    background do
      login_as(wrangler)
    end
    
    scenario "sees crop wranglers listed on the crop wrangler page" do
      visit root_path
      click_link 'Crop Wrangling'

      within '.crop_wranglers' do
        expect(page).to have_content 'Crop Wranglers:'
        crop_wranglers.each do |crop_wrangler|
          page.should have_link crop_wrangler.login_name, :href => member_path(crop_wrangler)
        end
      end
    end
  
    scenario "can see list of crops with extra detail of who created a crop" do
      visit root_path
      click_link 'Crop Wrangling'
      within '.table' do
        expect(page).to have_content "#{crops.first.creator.login_name}"
      end
    end
      
    scenario "visiting a crop can see wrangler links" do
      visit crop_path(crops.first)
      expect(page).to have_content 'You are a CROP WRANGLER'
      expect(page).to have_link 'Edit crop'
      expect(page).to have_link 'Delete crop'
    end
    
  end
  
  context "signed in non-wrangler" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:member) { FactoryGirl.create(:member) }

    background do
      login_as(member)
    end

    scenario "can't see wrangling page" do
      visit root_path
      expect(page).not_to have_link "Crop Wrangling"
    end
    
  end
end
