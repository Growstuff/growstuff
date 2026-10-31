# frozen_string_literal: true

require 'rails_helper'

describe "Planting a crop", :js do
  context 'signed in' do
    include_context 'signed in member'
    # name is aaa to ensure it is ordered first
    let!(:garden)            { create(:garden, name: 'aaa', owner: member) }
    let!(:planting)          { create(:planting, garden:, owner: garden.owner, planted_at: Date.parse("2013-3-10")) }
    let!(:tomato)            { create(:tomato) }
    let!(:finished_planting) { create(:finished_planting, owner: garden.owner, garden:, crop: tomato) }

    it "View gardens" do
      visit gardens_path
      expect(page).to have_content "Everyone's gardens"
      visit member_gardens_path(garden.owner)
      expect(page).to have_content "#{garden.owner.login_name}'s gardens"
    end

    it "Marking a garden as inactive" do
      visit garden_path(garden)
      within('.garden-actions') { click_link 'Actions' }
      accept_confirm do
        click_link "Mark as inactive"
      end
      expect(page).to have_content "Garden was successfully updated"
      expect(page).to have_content "This garden is inactive"

      within('.garden-actions') { click_link 'Actions' }
      expect(page).to have_link "Mark as active"
      expect(page).to have_no_link "Mark as inactive"
    end

    it "List only active gardens" do
      visit garden_path(garden)
      within('.garden-actions') { click_link 'Actions' }
      accept_confirm do
        click_link "Mark as inactive"
      end
      visit gardens_path
      expect(page).to have_no_link garden_path(garden)
    end

    it "Create new garden" do
      visit new_garden_path
      fill_in "Name", with: "New garden"
      click_button "Save"
      expect(page).to have_content "Garden was successfully created"
      expect(page).to have_content "New garden"
    end

    context "Clicking edit from the index page" do
      before do
        visit gardens_path
      end

      it "button on index to edit garden opens the form over the list" do
        click_link 'Actions', match: :first
        click_link href: edit_garden_path(garden)
        expect(page).to have_css '[role=dialog]', text: "Edit #{garden.name}"
        expect(page).to have_current_path(gardens_path)
      end
    end

    context 'When a garden has a garden type' do
      let(:garden_type) { create(:garden_type) }
      let(:garden_with_type) { create(:garden, garden_type:) }

      before { visit garden_path(garden_with_type) }

      it "labels the garden type tile" do
        expect(page).to have_css '.fact-card h3', text: 'Type'
      end

      it "shows the garden type's name" do
        expect(page).to have_css '.fact-type', text: garden_type.name
      end
    end

    it "Edit garden" do
      visit new_garden_path
      fill_in "Name", with: "New garden"
      click_button "Save"
      expect(page).to have_content "Garden was successfully created"
      within('.garden-actions') { click_link 'Actions' }
      within '.garden-actions' do
        click_link 'Edit'
      end
      fill_in "Name", with: "Different name"
      click_button "Save"
      expect(page).to have_content "Garden was successfully updated"
      expect(page).to have_content "Different name"
    end

    it "Delete garden" do
      visit new_garden_path
      fill_in "Name", with: "New garden"
      click_button "Save"
      expect(page).to have_content "Garden was successfully created"
      within('.garden-actions') { click_link 'Actions' }
      accept_confirm do
        click_link 'Delete'
      end
      expect(page).to have_content "Garden was successfully deleted"
      expect(page).to have_content "#{garden.owner}'s gardens"
    end

    describe "Making a planting inactive from garden show" do
      it do
        visit garden_path(garden)
        within('.planting-quick-actions') { click_link "Actions for #{planting.display_name}" }
        click_link "Mark as finished"
        expect(page).to have_content 'Finished'
      end
    end

    it "List only active plantings on a garden" do
      visit gardens_path
      expect(page).to have_no_content finished_planting.crop_name
    end
  end

  # TODO:     include_examples 'is accessible'
end
