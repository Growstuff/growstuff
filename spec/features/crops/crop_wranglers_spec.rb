require 'rails_helper'

describe "crop wranglers", js: true do
  context "signed in wrangler" do
    let!(:crop_wranglers) { create_list :crop_wrangling_member, 3 }
    let(:wrangler)        { crop_wranglers.first                  }
    let!(:crops)          { create_list :crop, 2                  }
    let!(:requested_crop) { create :crop_request                  }
    let!(:rejected_crop)  { create :rejected_crop                 }

    before { login_as wrangler }

    it "sees crop wranglers listed on the crop wrangler page" do
      visit root_path
      click_link wrangler.login_name
      click_link 'Crop Wrangling'

      within '.crop_wranglers' do
        expect(page).to have_content 'Crop Wranglers:'
        crop_wranglers.each do |crop_wrangler|
          expect(page).to have_link crop_wrangler.login_name, href: member_path(crop_wrangler)
        end
      end
    end

    it "can see list of crops with extra detail of who created a crop" do
      visit root_path
      click_link wrangler.login_name
      click_link 'Crop Wrangling'
      within '#recently-added-crops' do
        expect(page).to have_content crops.first.creator.login_name.to_s
      end
    end

    describe "visiting a crop can see wrangler links" do
      before { visit crop_path(crops.first) }

      it { expect(page).to have_content 'You are a CROP WRANGLER' }
      it { expect(page).to have_link 'Edit' }
      it { expect(page).to have_link 'Delete' }
    end

    it "can create a new crop" do
      visit root_path
      click_link wrangler.login_name
      click_link 'Crop Wrangling'
      click_link 'Add Crop'
      fill_in 'Name', with: "aubergine"
      fill_in 'en_wikipedia_url', with: "http://en.wikipedia.org/wiki/Maize"
      fill_in 'sci_name[1]', with: "planticus maximus"
      click_on 'Save'
      expect(page).to have_content 'crop was successfully created.'
      expect(page).to have_content 'planticus maximus'
    end

    it "View pending crops" do
      visit crop_path(requested_crop)
      expect(page).to have_content "This crop is currently pending approval."
      expect(page).to have_content "Please approve this even though it's fake."
    end

    it "View rejected crops" do
      visit crop_path(rejected_crop)
      expect(page).to have_content "This crop was rejected for the following reason: Totally fake"
    end
  end

  context "signed in non-wrangler" do
    let!(:crop_wranglers) { create_list :crop_wrangling_member, 3 }
    let(:member) { create :member }

    before { login_as member }

    it "can't see wrangling page without js", js: false do
      visit root_path
      expect(page).not_to have_link "Crop Wrangling"
    end

    it "can't see wrangling page with js" do
      visit root_path
      click_link member.login_name
      expect(page).not_to have_link "Crop Wrangling"
    end
  end
end
