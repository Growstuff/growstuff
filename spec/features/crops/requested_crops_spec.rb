require 'rails_helper'

feature "Crop - " do
  let(:member) { create :member }
  let!(:requested_crop) { create :crop, requester: member, approval_status: 'pending', name: 'puha for dinner' }

  background do
    login_as member
    visit requested_crops_path
  end

  scenario "creating a crop with multiple scientific and alternate name", :js do
    expect(page).to have_content "puha for dinner"
  end
end
