# frozen_string_literal: true

require 'rails_helper'

describe "combining seed library filters" do
  include_context 'signed in member'

  let(:tomato) { create(:crop, name: 'tomato') }
  let(:cabbage) { create(:crop, name: 'cabbage') }
  let(:kale) { create(:crop, name: 'kale') }

  before do
    create(:seed, owner: member, crop: tomato, source: 'retail outlet', heirloom: 'heirloom')
    create(:seed, owner: member, crop: cabbage, source: 'retail outlet', heirloom: 'hybrid')
    create(:seed, owner: member, crop: kale, source: 'my own seed saving', heirloom: 'heirloom')
  end

  context "with bought and heirloom both chosen" do
    before { visit member_seeds_path(member, from: 'retail', heirloom: 'heirloom') }

    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'kale') }
    it { expect(page).to have_css('.seed-chip.active', text: 'Retail outlet') }
    it { expect(page).to have_css('.seed-chip.active', text: 'Heirloom only') }
  end

  context "when grouping with filters chosen" do
    before { visit member_seeds_path(member, from: 'bought', heirloom: 'heirloom', group: 'source') }

    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'Retail outlet', count: 1) }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'My own seed saving') }
  end

  context "when filtered and choosing the finished tab" do
    before do
      visit member_seeds_path(member, from: 'bought', group: 'year')
      click_link 'Finished'
    end

    it { expect(page).to have_current_path member_seeds_path(member, from: 'bought', group: 'year', finished: 1) }
  end

  context "when filtered and choosing past sow-by" do
    before do
      create(:seed, owner: member, crop: tomato, source: 'retail outlet', plant_before: Date.new(2020, 12, 31))
      visit member_seeds_path(member, from: 'bought')
      click_link 'Show me'
    end

    it { expect(page).to have_current_path member_seeds_path(member, from: 'bought', past: 1) }
  end

  context "when filtered and choosing everyone" do
    before do
      visit member_seeds_path(member, from: 'bought', heirloom: 'heirloom', group: 'year')
      click_link 'Everyone'
    end

    it { expect(page).to have_current_path seeds_path(from: 'bought', heirloom: 'heirloom', group: 'year') }
  end

  context "when choosing mine after choosing a distance" do
    before do
      visit seeds_path(within: 50, from: 'bought', heirloom: 'heirloom')
      click_link 'Mine'
    end

    it { expect(page).to have_current_path member_seeds_path(member, from: 'bought', heirloom: 'heirloom') }
  end

  context "when viewing my own seeds" do
    before { visit member_seeds_path(member) }

    it { expect(page).to have_no_css('.seed-field-label', text: 'Distance') }
    it { expect(page).to have_css('.seed-field-label', text: 'Sharing') }
  end

  context "when filtered and choosing mine" do
    before do
      visit seeds_path(from: 'bought', scope: 'following')
      click_link 'Mine'
    end

    it { expect(page).to have_current_path member_seeds_path(member, from: 'bought') }
  end

  context "when filtered by a source and sowing month" do
    before do
      create(:seed, owner: member, crop: cabbage, source: 'retail outlet', sow_months: [9, 10])
      visit member_seeds_path(member, from: 'bought', sow_month: 9)
    end

    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'tomato') }
  end

  context "when nothing matches the filters" do
    before { visit member_seeds_path(member, from: 'traded', heirloom: 'heirloom', sow_month: 3) }

    it "offers to take them all off, keeping the grouping" do
      expect(page).to have_link('Show all seeds', href: member_seeds_path(member))
    end
  end

  context "when looking at a friend's seeds among everyone's" do
    let(:friend) { create(:member, login_name: 'Fiona') }

    before do
      create(:seed, owner: friend, crop: kale, tradable_to: 'locally')
      create(:seed, owner: create(:member), crop: tomato, tradable_to: 'locally')
      visit seeds_path(gardener: 'Fiona')
    end

    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'kale') }
    it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'tomato') }
    it { expect(page).to have_field('Gardener', with: 'Fiona') }
  end

  context "when viewing my own seeds without a gardener search" do
    before { visit member_seeds_path(member) }

    it { expect(page).to have_no_field('Gardener') }
  end
end
