require 'rails_helper'
require 'custom_matchers'

feature "Harvesting a crop", :js, :elasticsearch do
  let(:member) { create :member }
  let!(:maize) { create :maize }
  let!(:plant_part) { create :plant_part }
  let(:planting) { create :planting, crop: maize, owner: member }

  background do
    login_as member
    visit new_harvest_path
    sync_elasticsearch [maize]
  end

  it_behaves_like "crop suggest", "harvest", "crop"

  it "has the required fields help text" do
    expect(page).to have_content "* denotes a required field"
  end

  it "displays required and optional fields properly" do
    expect(page).to have_selector ".form-group.required", text: "What did you harvest?"
    expect(page).to have_optional 'input#harvest_quantity'
    expect(page).to have_optional 'input#harvest_weight_quantity'
    expect(page).to have_optional 'textarea#harvest_description'
  end

  scenario "Creating a new harvest", :js do
    fill_autocomplete "crop", with: "mai"
    select_from_autocomplete "maize"

    within "form#new_harvest" do
      select plant_part.name, from: 'harvest[plant_part_id]'
      fill_in "When?", with: "2014-06-15"
      fill_in "How many?", with: 42
      fill_in "Weighing (in total):", with: 42
      fill_in "Notes", with: "It's killer."
      click_button "Save"
    end

    expect(page).to have_content "harvest was successfully created."
  end

  context "Clicking edit from the index page" do
    let!(:harvest) { create :harvest, crop: maize, owner: member }

    background do
      visit harvests_path
    end

    scenario "button on index to edit harvest" do
      click_link "edit_harvest_glyphicon"
      expect(current_path).to eq edit_harvest_path(harvest)
      expect(page).to have_content 'Editing harvest'
    end
  end

  scenario "Clicking link to owner's profile" do
    visit harvests_by_owner_path(member)
    click_link "View #{member}'s profile >>"
    expect(current_path).to eq member_path member
  end

  scenario "Harvesting from crop page" do
    visit crop_path(maize)
    click_link "Harvest this"
    within "form#new_harvest" do
      select plant_part.name, from: 'harvest[plant_part_id]'
      expect(page).to have_selector "input[value='maize']"
      click_button "Save"
    end

    expect(page).to have_content "harvest was successfully created."
    expect(page).to have_content "maize"
  end

  scenario "Harvesting from planting page" do
    planting = create :planting, crop: maize, owner: member, garden: member.gardens.first
    visit planting_path(planting)
    within ".planting-actions" do
      click_link "Harvest"
    end

    select plant_part.name, from: 'harvest[plant_part_id]'
    click_button "Save"

    expect(page).to have_content "harvest was successfully created."
    expect(page).to have_content planting.garden.name
    expect(page).to have_content "maize"
  end

  context "Editing a harvest" do
    let(:existing_harvest) { create :harvest, crop: maize, owner: member }
    let!(:other_plant_part) { create :plant_part, name: 'chocolate' }

    background do
      visit harvest_path(existing_harvest)
      click_link "Edit"
    end

    scenario "Saving without edits" do
      # Check that the autosuggest helper properly fills inputs with
      # existing resource's data
      click_button "Save"
      expect(page).to have_content "harvest was successfully updated."
      expect(page).to have_content "maize"
    end

    scenario "change plant part" do
      select other_plant_part.name, from: 'harvest[plant_part_id]'
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

    background do
      visit harvest_path(existing_harvest)
    end

    scenario "linking to a planting" do
      expect(page).to have_content planting.to_s
      choose("harvest_planting_id_#{existing_planting.id}")
      click_button "save"
      expect(page).to have_link(href: planting_path(existing_planting))
    end
  end
end
