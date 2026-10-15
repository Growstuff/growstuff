# frozen_string_literal: true

require 'rails_helper'

describe "changing the seeds shown without reloading", :js do
  let(:owner) { create(:member) }
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:cabbage) { create(:crop, name: 'cabbage') }

  before do
    create(:seed, owner:, crop: tomato, heirloom: 'heirloom')
    create(:seed, owner:, crop: cabbage, heirloom: 'hybrid')
    visit member_seeds_path(owner)
    page.execute_script('window.seedLibraryMarker = "same page"')
  end

  context "when choosing a chip" do
    before { click_link 'Heirloom only' }

    it { expect(page).to have_current_path member_seeds_path(owner, from: 'heirloom') }
    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
    it { expect(page).to have_css('.seed-chips .active', text: 'Heirloom only') }

    it "does not load a new page" do
      expect(page.evaluate_script('window.seedLibraryMarker')).to eq 'same page'
    end
  end

  context "when choosing a crop" do
    before do
      fill_in 'Search seeds by crop', with: 'tom'
      find('.crop-picker-option', text: 'tomato').click
    end

    it { expect(page).to have_current_path member_seeds_path(owner, crop: tomato.slug) }
    it { expect(page).to have_css('.seed-crop', text: 'tomato') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
    it { expect(page).to have_css('.seed-search-summary', text: '1 packet of tomato seeds') }
  end

  context "when clearing the crop" do
    before do
      visit member_seeds_path(owner, crop: tomato.slug)
      find('.seed-crop-clear').click
    end

    it { expect(page).to have_current_path member_seeds_path(owner) }
    it { expect(page).to have_field('Search seeds by crop') }
    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage') }
  end

  context "when changing the grouping" do
    before { click_link 'Heirloom or hybrid' }

    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'Heirloom') }
    it { expect(page).to have_css('.seed-chip.active', text: 'Heirloom or hybrid') }
  end

  context "when changing to the list" do
    before { click_link 'List' }

    it { expect(page).to have_table(class: 'seed-list') }
    it { expect(page).to have_current_path member_seeds_path(owner, view: 'list') }
  end

  context "when going to the finished tab" do
    before do
      create(:seed, owner:, crop: tomato, finished: true)
      visit member_seeds_path(owner)
      click_link 'Finished'
    end

    it { expect(page).to have_current_path member_seeds_path(owner, finished: 1) }
    it { expect(page).to have_css('.nav-link.active', text: 'Finished') }
  end

  context "when going back" do
    before do
      click_link 'Heirloom only'
      find('.seed-chips .active', text: 'Heirloom only') # the new results are in
      page.go_back
    end

    it { expect(page).to have_current_path member_seeds_path(owner) }
    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage') }
    it { expect(page).to have_css('.seed-chips .active', text: 'All') }
  end

  context "when a pile is in the new results" do
    before do
      create_list(:seed, 3, owner:, crop: tomato, heirloom: 'heirloom')
      click_link 'Heirloom only'
      click_button 'tomato, 4 packets. Open to see each packet'
    end

    it { expect(page).to have_css('.seed-group .seed-group-packet', count: 4) }
  end

  context "when going to another member's page" do
    include_context 'signed in member'

    before do
      visit member_seeds_path(owner)
      click_link 'Everyone'
    end

    it { expect(page).to have_current_path seeds_path }
  end
end
