require 'rails_helper'

feature "crop wranglers" do
  context "signed in member" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:member){crop_wranglers.first}

    background do
      login_as(member)
    end

    scenario "crop wranglers are listed on the crop wrangler page" do
      visit root_path
      click_link 'Crop Wrangling'

      within '.crop_wranglers' do
        expect(page).to have_content 'Crop Wranglers:'
        crop_wranglers.each do |crop_wrangler|
          page.should have_link crop_wrangler.login_name, :href => member_path(crop_wrangler)
        end
      end
    end
  end
end
