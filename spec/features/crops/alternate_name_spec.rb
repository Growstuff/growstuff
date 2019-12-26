# frozen_string_literal: true

require 'rails_helper'

describe "Alternate names", js: true do
  let!(:alternate_eggplant) { create :alternate_eggplant }
  let(:crop)                { alternate_eggplant.crop    }

  shared_examples 'show alt names' do
    it "can see alternate names on crop page" do
      visit crop_path(alternate_eggplant.crop)
      # expect(page.status_code).to equal 200
      expect(page).to have_content alternate_eggplant.name
    end

    it "can see page for alternate names" do
      visit alternate_names_path
      expect(page).to have_content alternate_eggplant.name
    end
  end

  shared_examples 'edit alt names' do
    let!(:crop_wranglers) { create_list :crop_wrangling_member, 3 }

    it "can edit alternate names" do
      visit crop_path(crop)
      # expect(page.status_code).to equal 200
      expect(page).to have_content "CROP WRANGLER"
      expect(page).to have_content alternate_eggplant.name
      click_link 'aubergine'
      expect(page).to have_link "Edit", href: edit_alternate_name_path(alternate_eggplant)
      within('.alternate_names') { click_on "Edit" }
      # expect(page.status_code).to equal 200
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "alternative aubergine"
      Percy.snapshot(page, name: 'Crop wrangler adding alternate name')
      click_on "Save"
      # expect(page.status_code).to equal 200
      expect(page).to have_content "alternative aubergine"
      expect(page).to have_content 'Alternate name was successfully updated'
    end

    it "can delete alternate names" do
      visit crop_path(alternate_eggplant.crop)
      click_link('aubergine', href: '#')
      accept_confirm do
        click_link 'Delete'
      end
      expect(page).not_to have_content alternate_eggplant.name
      expect(page).to have_content 'Alternate name was successfully deleted'
    end

    it "can add alternate names" do
      visit crop_path(crop)
      expect(page).to have_link "Add",
                                href: new_alternate_name_path(crop_id: crop.id)
      within('.alternate_names') { click_on "Add" }
      # expect(page.status_code).to equal 200
      expect(page).to have_css "option[value='#{crop.id}'][selected=selected]"
      fill_in 'Name', with: "not an aubergine"
      click_on "Save"
      # expect(page.status_code).to equal 200
      expect(page).to have_content "not an aubergine"
      expect(page).to have_content 'Alternate name was successfully created'
    end

    it "shows alternate-name page" do
      visit alternate_name_path(alternate_eggplant)
      # expect(page.status_code).to equal 200
      expect(page).to have_content alternate_eggplant.crop.name
    end

    context "When alternate name is rejected" do
      let(:rejected_crop) { create :rejected_crop }
      let(:pending_alt_name) { create :alternate_name, crop: rejected_crop }

      it "Displays crop rejection message" do
        visit alternate_name_path(pending_alt_name)
        expect(page).to have_content "This crop was rejected for the following reason: Totally fake"
        Percy.snapshot(page, name: 'Rejecting crops')
      end
    end
  end

  context 'Anonymous' do
    include_examples 'show alt names'
  end

  context 'Signed in member' do
    include_context 'signed in member'
    include_examples 'show alt names'
  end

  context 'Crop wrangler' do
    include_context 'signed in crop wrangler'
    include_examples 'show alt names'
    include_examples 'edit alt names'
  end

  context 'Admin' do
    include_context 'signed in admin'
    include_examples 'show alt names'
    include_examples 'edit alt names'
  end
end
