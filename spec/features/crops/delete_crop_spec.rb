require 'rails_helper'

describe "Delete crop spec" do
  context "As a crop wrangler" do
    let(:wrangler)       { FactoryBot.create :crop_wrangling_member }
    let!(:pending_crop)  { FactoryBot.create :crop_request          }
    let!(:approved_crop) { FactoryBot.create :crop                  }

    before { login_as wrangler }

    it "Delete approved crop" do
      visit crop_path(approved_crop)
      click_link 'Actions'
      click_link 'Delete'
      dismiss_confirm {click_link 'OK'}
      expect(page).to have_content "crop was successfully destroyed"
    end

    it "Delete pending crop" do
      visit crop_path(pending_crop)
      click_link 'Actions'
      click_link 'Delete'
      dismiss_confirm {click_link 'OK'}
      expect(page).to have_content "crop was successfully destroyed"
    end
  end
end
