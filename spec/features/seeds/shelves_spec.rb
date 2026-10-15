# frozen_string_literal: true

require 'rails_helper'

describe "seed shelves" do
  let(:owner) { create(:member) }
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:brandywine) { create(:crop, name: 'Brandywine tomato', parent: tomato) }
  let(:cabbage) { create(:crop, name: 'cabbage') }

  context "with seeds of two varieties of one parent crop" do
    before do
      create(:seed, owner:, crop: brandywine)
      create(:seed, owner:, crop: tomato)
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('.seed-shelf', count: 1) }
    it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
    it { expect(page).to have_css('.seed-shelf .seed-packet', count: 2) }
  end

  context "with seeds of different crops" do
    before do
      create(:seed, owner:, crop: tomato)
      create(:seed, owner:, crop: cabbage)
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('.seed-shelf', count: 2) }
  end

  context "with more than three shelves" do
    before do
      %w(apple beet carrot daikon).each { |name| create(:seed, owner:, crop: create(:crop, name:)) }
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('details.seed-shelf[open]', count: 3) }
    it { expect(page).to have_css('details.seed-shelf:not([open])', count: 1) }
  end

  context "with several packets of one variety" do
    before do
      create_list(:seed, 3, owner:, crop: brandywine)
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('.seed-stack', count: 1) }
    it { expect(page).to have_css('.seed-stack-count', text: '×3') }
  end

  context "with a single packet" do
    before do
      create(:seed, owner:, crop: tomato)
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_no_css('.seed-stack') }
  end

  describe "add seeds link on a shelf" do
    before { create(:seed, owner:, crop: tomato) }

    context "when viewing your own seeds" do
      include_context 'signed in member'
      let(:owner) { member }

      before { visit member_seeds_path(owner) }

      it { expect(page).to have_link('+ add seeds', href: new_seed_path(crop_id: tomato.id)) }
    end

    context "when viewing another member's seeds" do
      before { visit member_seeds_path(owner) }

      it { expect(page).to have_no_link('+ add seeds', href: new_seed_path(crop_id: tomato.id)) }
    end
  end

  describe "list view" do
    before do
      create_list(:seed, 2, owner:, crop: brandywine, saved_at: Date.new(2025, 3, 4))
      visit member_seeds_path(owner, view: 'list')
    end

    it { expect(page).to have_table(class: 'seed-list') }
    it { expect(page).to have_no_css('.seed-packet') }
    it { expect(page).to have_css('.seed-list-shelf', text: 'tomato') }
    it { expect(page).to have_css('.seed-list-packet', count: 2) }
  end

  describe "grouping" do
    before do
      create(:seed, owner:, crop: tomato, heirloom: 'heirloom')
      create(:seed, owner:, crop: cabbage, heirloom: 'hybrid')
    end

    context "when grouped by heirloom or hybrid" do
      before { visit member_seeds_path(owner, group: 'heirloom') }

      it { expect(page).to have_css('.seed-shelf-bar h3', text: /Heirloom|Hybrid/, count: 2) }
      it { expect(page).to have_no_link('+ add seeds') }
    end

    context "when grouped by year saved without a saved date" do
      before { visit member_seeds_path(owner, group: 'year') }

      it { expect(page).to have_css('.seed-shelf-bar h3', text: 'Year not recorded') }
    end
  end

  describe "packet details" do
    before do
      create(:seed, owner:, crop: tomato, source: 'my own seed saving', heirloom: 'heirloom', saved_at: Date.new(2025, 3, 4))
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('.seed-packet', text: /own saving/i) }
    it { expect(page).to have_css('.seed-pill', text: 'Heirloom') }
    it { expect(page).to have_css('.seed-packet-rule', text: 'saved 2025') }
  end

  describe "page header" do
    before do
      create(:seed, owner:, crop: tomato, source: 'my own seed saving')
      create(:seed, owner:, crop: cabbage, source: 'retail outlet')
      visit member_seeds_path(owner)
    end

    it { expect(page).to have_css('h1', text: "#{owner.login_name}'s seed library") }
    it { expect(page).to have_css('.seed-head-stats li', text: '2 packets') }
    it { expect(page).to have_css('.seed-head-stats li', text: '1 my own saving') }
  end
end
