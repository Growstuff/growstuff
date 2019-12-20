# frozen_string_literal: true

require 'rails_helper'

describe "Requesting Crops" do
  let!(:requested_crop) { create :crop, requester: member, approval_status: 'pending', name: 'puha for dinner' }

  context 'signed in' do
    include_context 'signed in member'
    before { visit requested_crops_path }

    it "creating a crop with multiple scientific and alternate name", :js do
      expect(page).to have_content "puha for dinner"
    end
  end
end
