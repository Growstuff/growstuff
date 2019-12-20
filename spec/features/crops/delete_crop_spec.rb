# frozen_string_literal: true

require 'rails_helper'

describe "Delete crop spec" do
  shared_examples 'delete crop' do
    let!(:pending_crop)  { FactoryBot.create :crop_request          }
    let!(:approved_crop) { FactoryBot.create :crop                  }
    it "deletes approved crop" do
      visit crop_path(approved_crop)
      click_link 'Actions'
      accept_confirm do
        click_link 'Delete'
      end
      expect(page).to have_content "crop was successfully destroyed"
    end

    it "deletes pending crop" do
      visit crop_path(pending_crop)
      click_link 'Actions'
      accept_confirm do
        click_link 'Delete'
      end
      expect(page).to have_content "crop was successfully destroyed"
    end
  end

  context "As a crop wrangler" do
    include_context 'signed in crop wrangler'
    include_examples 'delete crop'
  end

  context 'admin' do
    include_context 'signed in admin'
    include_examples 'delete crop'
  end
end
