# frozen_string_literal: true

require 'rails_helper'
require 'custom_matchers'

describe "Seeds", :js, :search do
  context 'signed in' do
    include_context 'signed in member'
    let!(:maize) { create(:maize) }

    before { visit new_seed_path }

    it_behaves_like "crop suggest", "seed", "crop"

    describe "displays required and optional fields properly" do
      # NOTE: The required behaviour is pushed down to the control itself, not the form-group as of rails 7.1.
      # Modern browsers enforce the required behaviour better than us doing it ourselves.
      it { expect(page).to have_selector "label", text: "Crop" }
      it { expect(page).to have_selector 'input#seed_quantity' }
      it { expect(page).to have_selector 'input#seed_plant_before' }
      it { expect(page).to have_selector 'input#seed_days_until_maturity_min' }
      it { expect(page).to have_selector 'input#seed_days_until_maturity_max' }
      it { expect(page).to have_selector 'label', text: 'Organic?' }
      it { expect(page).to have_selector 'label', text: 'GMO?' }
      it { expect(page).to have_selector 'label', text: 'Heirloom?' }
      it { expect(page).to have_selector 'textarea#seed_description' }
      it { expect(page).to have_selector 'label', text: 'Will trade' }
    end

    describe "Adding a new seed", :js do
      before do
        fill_autocomplete "crop", with: " "
        select_from_autocomplete "maize"
        within "form#new_seed" do
          fill_in "Quantity", with: 42
          fill_in "Plant before", with: TIme.new(2014, 6, 15)
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
      it { expect(find('.seedfacts--quantity')).to have_content "42" }
      it { expect(find('.seedfacts--maturity')).to have_content "999–1999" }
      it { expect(find('.seedtitle--organic')).to have_content "certified organic" }
      it { expect(find('.seedtitle--gmo')).to have_content "non-certified GMO-free" }
      it { expect(find('.seedtitle--heirloom')).to have_content "heirloom" }
      it { expect(find('.seed--description')).to have_content "It's killer." }
    end

    describe "Adding a seed from crop page" do
      before do
        visit crop_path(maize)
        click_link "Save seeds"
      end

      describe 'no trades' do
        before { click_button "Save #{maize.name} seeds." }

        it { expect(page).to have_content "nowhere" }
        it { expect(page).to have_content "Successfully added maize seed to your stash" }
        it { expect(page).to have_content "maize" }
      end

      describe 'tradeable' do
        before { click_button "locally" }

        it { expect(page).to have_content "locally" }
        it { expect(page).to have_content "Successfully added maize seed to your stash" }
        it { expect(page).to have_content "maize" }
      end
    end
  end
end
