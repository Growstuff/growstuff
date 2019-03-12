require('rails_helper')

feature "Delete crop spec" do
  context "As a crop wrangler" do
    let(:wrangler) { FactoryBot.create(:crop_wrangling_member) }
    let!(:pending_crop) { FactoryBot.create(:crop_request) }
    let!(:approved_crop) { FactoryBot.create(:crop) }

    background { login_as wrangler }

    scenario "Delete approved crop" do
      visit crop_path(approved_crop)
      click_link 'Delete'
      expect(page).to(have_content("crop was successfully destroyed"))
    end

    scenario "Delete pending crop" do
      visit crop_path(pending_crop)
      click_link 'Delete'
      expect(page).to(have_content("crop was successfully destroyed"))
    end
  end
end
