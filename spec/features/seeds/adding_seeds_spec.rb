require 'rails_helper'
require 'custom_matchers'

describe "Seeds", :js, :elasticsearch do
  context 'signed in' do
    include_context 'signed in member'
    let!(:maize) { create :maize }

    before { visit new_seed_path }

    it_behaves_like "crop suggest", "seed", "crop"

    it "has the required fields help text" do
      expect(page).to have_content "* denotes a required field"
    end

    describe "displays required and optional fields properly" do
      it { expect(page).to have_selector ".form-group.required", text: "Crop" }
      it { expect(page).to have_selector 'input#seed_quantity' }
      it { expect(page).to have_selector 'input#seed_plant_before' }
      it { expect(page).to have_selector 'input#seed_days_until_maturity_min' }
      it { expect(page).to have_selector 'input#seed_days_until_maturity_max' }
      it { expect(page).to have_selector '.form-group.required', text: 'Organic?' }
      it { expect(page).to have_selector '.form-group.required', text: 'GMO?' }
      it { expect(page).to have_selector '.form-group.required', text: 'Heirloom?' }
      it { expect(page).to have_selector 'textarea#seed_description' }
      it { expect(page).to have_selector '.form-group.required', text: 'Will trade' }
    end

    describe "Adding a new seed", js: true do
      before do
        fill_autocomplete "crop", with: "mai"
        select_from_autocomplete "maize"
        within "form#new_seed" do
          fill_in "Quantity", with: 42
          fill_in "Plant before", with: "2014-06-15"
          fill_in "min", with: 999
          fill_in "max", with: 1999
          select "certified organic", from: "Organic?"
          select "non-certified GMO-free", from: "GMO?"
          select "heirloom", from: "Heirloom?"
          fill_in "Description", with: "It's killer."
          select "internationally", from: "Will trade"
          click_button "Save"
        end
      end

      it { expect(page).to have_content "Successfully added maize seed to your stash" }
      it { expect(page).to have_content "Quantity: 42" }
      it { expect(page).to have_content "Days until maturity: 999–1999" }
      it { expect(page).to have_content "certified organic" }
      it { expect(page).to have_content "non-certified GMO-free" }
      it { expect(page).to have_content "Heirloom? heirloom" }
      it { expect(page).to have_content "It's killer." }
    end

    describe "Adding a seed from crop page" do
      before do
        visit crop_path(maize)
        click_link "Add maize seeds to stash"
        within "form#new_seed" do
          expect(page).to have_selector "input[value='maize']"
          click_button "Save"
        end
      end

      it { expect(page).to have_content "Successfully added maize seed to your stash" }
      it { expect(page).to have_content "maize" }
    end
  end
end
