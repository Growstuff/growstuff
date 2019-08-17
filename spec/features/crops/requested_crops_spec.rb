require 'rails_helper'

describe "Requesting Crops" do
  let!(:requested_crop) { create :crop, requester: member, approval_status: 'pending', name: 'puha for dinner' }

  include_context 'signed in member' do
    before { visit requested_crops_path }

    it "creating a crop with multiple scientific and alternate name", :js do
      expect(page).to have_content "puha for dinner"
    end
  end
end
