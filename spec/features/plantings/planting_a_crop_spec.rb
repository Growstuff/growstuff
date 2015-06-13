require "rails_helper"

feature "Planting a crop", :js => true do
  let(:member)   { FactoryGirl.create(:member) }
  let!(:maize)   { FactoryGirl.create(:maize) }
  let(:garden)   { FactoryGirl.create(:garden, owner: member) }
  let!(:planting) { FactoryGirl.create(:planting, garden: garden, planted_at: Date.parse("2013-3-10")) }

  background do
    login_as(member)
    visit new_planting_path
    sync_elasticsearch([maize])
  end

  it_behaves_like "crop suggest", "planting"

  scenario "Creating a new planting" do
    fill_autocomplete "crop", :with => "mai"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      click_button "Show Optional Fields"
      fill_in "When", :with => "2014-06-15"
      fill_in "How many?", :with => 42
      select "cutting", :from => "Planted from:"
      select "semi-shade", :from => "Sun or shade?"
      fill_in "Tell us more about it", :with => "It's rad."
      click_button "Save"
    end

    expect(page).to have_content "Planting was successfully created"
  end

  scenario "Planting from crop page" do
    visit crop_path(maize)
    click_link "Plant this"
    within "form#new_planting" do
      expect(page).to have_selector "input[value='maize']"
      click_button "Save"
    end

    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "maize"
  end
  
  scenario "Editing a planting to add details" do
    visit planting_path(planting)
    click_link "Edit"
    fill_in "Tell us more about it", :with => "Some extra notes"
    click_button "Save"
    expect(page).to have_content "Planting was successfully updated"
  end

  scenario "Marking a planting as finished" do
    fill_autocomplete "crop", :with => "mai"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      fill_in "When?", :with => "2014-07-01"
      check "Mark as finished"
      fill_in "Finished date", :with => "2014-08-30"

      # Trigger click instead of using Capybara"s uncheck
      # because a date selection widget is overlapping 
      # the checkbox preventing interaction.
      page.find("#planting_finished").trigger("click")
    end

    # Javascript removes the finished at date when the 
    # planting is marked unfinished.
    expect(page.find("#planting_finished_at").value).to eq("")

    within "form#new_planting" do
      page.find("#planting_finished").trigger("click")
    end

    # The finished at date was cached in Javascript in 
    # case the user clicks unfinished accidentally.
    expect(page.find("#planting_finished_at").value).to eq("2014-08-30")

    within "form#new_planting" do
      click_button "Save"
    end
    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "Finished: August 30, 2014"

    visit plantings_path
    expect(page).to have_content "August 30, 2014"
  end

  scenario "Marking a planting as finished without a date" do
    fill_autocomplete "crop", :with => "mai"
    select_from_autocomplete "maize"
    within "form#new_planting" do
      check "Mark as finished"
      click_button "Save"
    end
    expect(page).to have_content "Planting was successfully created"
    expect(page).to have_content "Finished: Yes (no date specified)"
  end

  describe "Marking a planting as finished from the show page" do
    let(:path)      { planting_path(planting) }
    let(:link_text) { "Mark as finished" }
    it_behaves_like "append date"
  end

  describe "Marking a planting as finished from the list page" do
    let(:path)      { plantings_path }
    let(:link_text) { "Mark as finished" }
    it_behaves_like "append date"
  end

end

