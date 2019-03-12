require 'rails_helper'

describe "Crop - " do
  let(:member) { create :member }
  let!(:requested_crop) { create :crop, requester: member, approval_status: 'pending', name: 'puha for dinner' }

  before do
    login_as member
    visit requested_crops_path
  end

  it "creating a crop with multiple scientific and alternate name", :js do
    expect(page).to have_content "puha for dinner"
  end
end
