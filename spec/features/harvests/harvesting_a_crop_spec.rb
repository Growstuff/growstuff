# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Harvesting a crop", :js, :search do
  context 'signed in' do
    include_context 'signed in member'
    let!(:maize)      { create :maize }
    let!(:plant_part) { create :plant_part }

    before { visit new_harvest_path }

    it_behaves_like "crop suggest", "harvest", "crop"

    it "has the required fields help text" do
      expect(page).to have_content "* denotes a required field"
    end

    describe "displays required and optional fields properly" do
      it { expect(page).to have_selector ".required", text: "What did you harvest?" }
      it { expect(page).to have_selector 'input#harvest_quantity' }
      it { expect(page).to have_selector 'input#harvest_weight_quantity' }
      it { expect(page).to have_selector 'textarea#harvest_description' }
    end

    it "Creating a new harvest", :js do
      fill_autocomplete "crop", with: "mai"
      select_from_autocomplete "maize"

      within "form#new_harvest" do
        choose plant_part.name
        fill_in "When?", with: "2014-06-15"
        fill_in "How many?", with: 42
        fill_in "Weighing (in total)", with: 42
        fill_in "Notes", with: "It's killer."
        click_button "Save"
      end

      expect(page).to have_content "harvest was successfully created."
    end

    describe 'member harvests' do
      before { visit member_harvests_path(member) }
      it { expect(page).to have_text "#{member.login_name}'s harvests" }
      it "Clicking link to owner's profile" do
        within '.login-name' do
          click_link member.login_name
        end
        expect(page).to have_current_path member_path(member), ignore_query: true
      end
    end

    describe "Harvesting from crop page" do
      before do
        visit crop_path(maize)
        click_link "Record harvest"
        click_link plant_part.name
      end

      it { expect(page).to have_content "harvest was successfully created." }
      it { expect(page).to have_content "maize" }
    end

    describe "Harvesting from planting page" do
      let!(:planting) { create :planting, crop: maize, owner: member, garden: member.gardens.first }
      before do
        visit planting_path(planting)
        click_link "Record harvest"
        click_link plant_part.name
      end

      it { expect(page).to have_content "harvest was successfully created." }
      it { expect(page).to have_content planting.garden.name }
      it { expect(page).to have_content "maize" }
    end

    context "Editing a harvest" do
      let(:existing_harvest)  { create :harvest, crop: maize, owner: member }
      let!(:other_plant_part) { create :plant_part, name: 'chocolate'       }

      before do
        visit harvest_path(existing_harvest)
        click_link 'Actions'
        click_link "Edit"
      end

      it "Saving without edits" do
        # Check that the autosuggest helper properly fills inputs with
        # existing resource's data
        click_button "Save"
        expect(page).to have_content "harvest was successfully updated."
        expect(page).to have_content "maize"
      end

      it "change plant part" do
        choose other_plant_part.name
        click_button "Save"
        expect(page).to have_content "harvest was successfully updated."
        expect(page).to have_content other_plant_part.name
      end
    end

    context "Viewing a harvest" do
      let(:existing_harvest) do
        create :harvest, crop: maize, owner: member,
                         harvested_at: Time.zone.today
      end
      let!(:existing_planting) do
        create :planting, crop: maize, owner: member,
                          planted_at: Time.zone.yesterday
      end

      before do
        visit harvest_path(existing_harvest)
      end

      it "linking to a planting" do
        expect(page).to have_content existing_planting.to_s
        choose("harvest_planting_id_#{existing_planting.id}")
        click_button "save"
        expect(page).to have_link(href: planting_path(existing_planting))
      end
    end
  end
end
