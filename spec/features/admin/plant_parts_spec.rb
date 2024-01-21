# frozen_string_literal: true

require 'rails_helper'

describe "plant parts", :js do
  include_context 'signed in admin'

  let(:plant_part) { create(:plant_part) }

  describe "navigating to plant parts admin with js" do
    before do
      visit admin_path
      within 'nav#crop_admin' do
        click_link "Plant parts"
      end
    end

    it { expect(page).to have_current_path plant_parts_path, ignore_query: true }
    it { expect(page).to have_link "New plant part" }
  end

  describe "adding a plant part" do
    before do
      visit plant_parts_path
      click_link "New plant part"
      expect(page).to have_current_path new_plant_part_path, ignore_query: true
      fill_in 'Name', with: "this is a new plant part"
      click_button 'Save'
    end

    it { expect(page).to have_current_path plant_part_path(PlantPart.last), ignore_query: true }
    it { expect(page).to have_content 'Plant part was successfully created' }
  end

  describe 'editing plant part' do
    before do
      @plant_part = plant_part
      visit plant_parts_path
      click_link 'Edit', href: edit_plant_part_path(@plant_part)
      fill_in 'Name', with: 'Something else'
      click_button 'Save'
      plant_part.reload
    end

    it { expect(page).to have_current_path plant_part_path(@plant_part), ignore_query: true }
    it { expect(page).to have_content 'Plant part was successfully updated' }
    it { expect(page).to have_content 'Something Else' }
  end

  describe 'deleting plant part' do
    before do
      @plant_part = plant_part
      visit plant_parts_path
      accept_confirm do
        click_link 'Delete', href: plant_part_path(@plant_part)
      end
    end

    it { expect(page).to have_current_path plant_parts_path, ignore_query: true }
    it { expect(page).to have_content 'Plant part was successfully destroyed' }
  end
end
