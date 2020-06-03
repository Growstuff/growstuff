# frozen_string_literal: true

require 'rails_helper'

describe "Crop", js: true do
  shared_context 'fill in form' do
    before do
      visit new_crop_path
      within "form#new_crop" do
        fill_in "crop_name", with: "Philippine flower"
        fill_in "en_wikipedia_url", with: "https://en.wikipedia.org/wiki/Jasminum_sambac"
        click_button class: "add-sciname-row"
        fill_in "sci_name[1]", with: "Jasminum sambac 1"
        fill_in "sci_name[2]", with: "Jasminum sambac 2"
        fill_in "alt_name[1]", with: "Sampaguita"
        click_button class: "add-altname-row"
        click_button class: "add-altname-row"
        fill_in "alt_name[2]", with: "Manol"
        click_button class: "add-altname-row"
        fill_in "alt_name[3]", with: "Jazmin"
        fill_in "alt_name[4]", with: "Matsurika"
      end
    end
  end
  shared_examples 'request crop' do
    describe "requesting a crop with multiple scientific and alternate name" do
      include_examples 'fill in form'
      before do
        within "form#new_crop" do
          fill_in "request_notes", with: "This is the Philippine national flower."
          click_button "Save"
        end
      end
      it { expect(page).to have_content 'crop was successfully created.' }
      it { expect(page).to have_content "This crop is currently pending approval." }
      it { expect(page).to have_content "Jasminum sambac 2" }
      it { expect(page).to have_content "Matsurika" }
    end
  end
  shared_examples 'create crop' do
    describe "creating a crop with multiple scientific and alternate name" do
      include_examples 'fill in form'
      before do
        click_button "Save"
      end
      it { expect(page).to have_content 'crop was successfully created.' }
      it { expect(page).to have_content "Jasminum sambac 2" }
      it { expect(page).to have_content "Matsurika" }
    end
  end

  context 'anon' do
    before { visit new_crop_path }
    it { expect(page).to have_content 'You need to sign in' }
  end
  context 'member' do
    include_context 'signed in member'
    include_examples 'request crop'
  end
  context 'crop wrangler' do
    include_context 'signed in crop wrangler'
    include_examples 'create crop'
  end
  context 'admin' do
    include_context 'signed in admin'
    include_examples 'create crop'
  end
end
