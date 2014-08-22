require 'spec_helper'

feature "crop wranglers" do
  context "signed in user" do
    let!(:crop_wranglers) { FactoryGirl.create_list(:crop_wrangling_member, 3) }
    let(:user){crop_wranglers.first}
    before :each do
      visit root_path
      click_link 'Sign in'
      fill_in 'Login', with: user.login_name
      fill_in 'Password', with: user.password
      click_button 'Sign in'
      page.should have_content user.login_name
    end

    scenario "crop wranglers are listed on the crop wrangler page" do
      click_link 'Crop Wrangling'

      within '.crop_wranglers' do
        expect(page).to have_content 'Crop Wranglers:'
        crop_wranglers.each_with_index do |crop_wrangler, index|
          link = find(".crop_wrangler:nth-child(#{index + 1}) a")
          expect(link.text).to eq(crop_wrangler.login_name)
          expect(link['href']).to eq(member_path(crop_wrangler))
        end
      end
    end
  end
end
