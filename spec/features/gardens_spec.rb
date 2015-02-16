require 'rails_helper'

feature "Planting a crop", :js => true do
  let!(:garden)   { FactoryGirl.create(:garden) }
  let!(:planting) { FactoryGirl.create(:planting, garden: garden, planted_at: Date.parse("2013-3-10")) }


  background do
    login_as(garden.owner)
  end

  scenario "View gardens" do
    visit gardens_path
    expect(page).to have_content "Everyone's gardens"
    click_link "View your gardens"
    expect(page).to have_content "#{garden.owner.login_name}'s gardens"
    click_link "View everyone's gardens"
    expect(page).to have_content "Everyone's gardens"
  end

  scenario "Marking a garden as inactive" do
    visit garden_path(garden)
    click_link "Mark as inactive"
    expect(page).to have_content "Garden was successfully updated"
    expect(page).to have_content "This garden is inactive"
    expect(page).to have_content "Mark as active"
    expect(page).not_to have_content "Mark as inactive"
  end

  scenario "Create new garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    expect(page).to have_content "Garden was successfully created"
    expect(page).to have_content "New garden"
  end

  scenario "Refuse to create new garden with negative area" do
    visit new_garden_path
    fill_in "Name", :with => "Negative Garden"
    fill_in "Area", :with => -5
    click_button "Save"
    expect(page).not_to have_content "Garden was successfully created"
    expect(page).to have_content "Area must be greater than or equal to 0"
  end

  scenario "Edit garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    click_link "Edit garden"
    fill_in "Name", :with => "Different name"
    click_button "Save"
    expect(page).to have_content "Garden was successfully updated"
    expect(page).to have_content "Different name"
  end

  scenario "Delete garden" do
    visit new_garden_path
    fill_in "Name", :with => "New garden"
    click_button "Save"
    visit garden_path(Garden.last)
    click_link "Delete garden"
    expect(page).to have_content "Garden was successfully deleted"
    expect(page).to have_content "#{garden.owner}'s gardens"
  end

  describe "Making a planting inactive from garden show" do
    let(:path) { garden_path(garden) }
    let(:link_text) { "Mark as finished" }

    it_behaves_like "append date"
  end

  describe "Inspect partial gardens/_area" , :type => :view  do
    it "Check unit of measurement SQUARE METER" do
      garden = FactoryGirl.create(:garden_square_metre)
      render(:partial => "gardens/area", locals: {:garden => garden})
      expect(response).to match(/m<sup>2<\/sup>/i)
    end

    it "Check unit of measurement NO AREA" do
      garden = FactoryGirl.create(:garden_no_area)
      render(:partial => "gardens/area", locals: {:garden => garden})
      expect(response).to eq('')
    end

    it "Check unit of measurement SQUARE FOOT" do
      garden = FactoryGirl.create(:garden_square_foot)
      render(:partial => "gardens/area", locals: {:garden => garden})
      expect(response).to match(/sqft/i)
    end

    it "Check unit of measurement HECTARE" do
      garden = FactoryGirl.create(:garden_hectare)
      render(:partial => "gardens/area", locals: {:garden => garden})
      expect(response).to match(/ha/i)
    end

    it "Check unit of measurement ACRE" do
      garden = FactoryGirl.create(:garden_acre)
      render(:partial => "gardens/area", locals: {:garden => garden})
      expect(response).to match(/acre/i)
    end
  end
end
