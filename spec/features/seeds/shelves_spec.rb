# frozen_string_literal: true

require 'rails_helper'

describe "seed shelves" do
  let(:owner) { create(:member) }
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:brandywine) { create(:crop, name: 'Brandywine tomato', parent: tomato) }
  let(:cabbage) { create(:crop, name: 'cabbage') }

  context "with seeds of two varieties of one parent crop" do
    let!(:brandywine_seed) { create(:seed, owner:, crop: brandywine) }
    let!(:tomato_seed) { create(:seed, owner:, crop: tomato) }

    before { visit member_seeds_path(owner) }

    it "puts them on one shelf" do
      expect(page).to have_css('.seed-shelf', count: 1)
    end

    it "names the shelf for the parent crop" do
      expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato')
    end

    it "shows a packet for each variety" do
      expect(page).to have_css('.seed-shelf .seed-card', count: 2)
    end
  end

  context "with seeds of different crops" do
    before do
      create(:seed, owner:, crop: tomato)
      create(:seed, owner:, crop: cabbage)
      visit member_seeds_path(owner)
    end

    it "gives each crop a shelf" do
      expect(page).to have_css('.seed-shelf', count: 2)
    end
  end

  context "with several packets of one variety" do
    before do
      create_list(:seed, 3, owner:, crop: brandywine)
      visit member_seeds_path(owner)
    end

    it "piles them in one stack" do
      expect(page).to have_css('.seed-stack', count: 1)
    end

    it "shows how many packets are in the stack" do
      expect(page).to have_css('.seed-stack-count', text: '×3')
    end
  end

  context "with a single packet" do
    before do
      create(:seed, owner:, crop: tomato)
      visit member_seeds_path(owner)
    end

    it "does not stack it" do
      expect(page).to have_no_css('.seed-stack')
    end
  end

  describe "add seeds link" do
    before { create(:seed, owner:, crop: tomato) }

    context "when viewing your own seeds" do
      include_context 'signed in member'
      let(:owner) { member }

      before { visit member_seeds_path(owner) }

      it { expect(page).to have_link('+ add seeds', href: new_seed_path(crop_id: tomato.id)) }
    end

    context "when viewing another member's seeds" do
      before { visit member_seeds_path(owner) }

      it { expect(page).to have_no_link('+ add seeds') }
    end
  end

  describe "in stock and finished tabs" do
    let!(:in_stock) { create(:seed, owner:, crop: tomato) }
    let!(:finished) { create(:seed, owner:, crop: cabbage, finished: true) }

    context "without choosing a tab" do
      before { visit member_seeds_path(owner) }

      it "shows seeds that are in stock" do
        expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato')
      end

      it "hides finished seeds" do
        expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage')
      end

      it "counts the finished seeds on their tab" do
        expect(page).to have_link('Finished 1')
      end
    end

    context "when on the finished tab" do
      before do
        visit member_seeds_path(owner)
        click_link 'Finished'
      end

      it "shows finished seeds" do
        expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage')
      end

      it "hides seeds that are in stock" do
        expect(page).to have_no_css('.seed-shelf-bar h3', text: 'tomato')
      end
    end
  end

  describe "list view" do
    let!(:brandywine_seeds) { create_list(:seed, 2, owner:, crop: brandywine, saved_at: Date.new(2025, 3, 4)) }

    before { visit member_seeds_path(owner, view: 'list') }

    it "shows a table instead of packets" do
      expect(page).to have_table(class: 'seed-list')
    end

    it "has no packet cards" do
      expect(page).to have_no_css('.seed-card')
    end

    it "names the parent crop's shelf" do
      expect(page).to have_css('.seed-list-shelf', text: 'tomato')
    end

    it "gives a row for each packet of a variety held in several" do
      expect(page).to have_css('.seed-list-packet', count: 2)
    end
  end

  describe "grouping" do
    before do
      create(:seed, owner:, crop: tomato, heirloom: 'heirloom')
      create(:seed, owner:, crop: cabbage, heirloom: 'hybrid')
      visit member_seeds_path(owner, group: 'heirloom')
    end

    it "makes a shelf for each value" do
      expect(page).to have_css('.seed-shelf-bar h3', text: /Heirloom|Hybrid/, count: 2)
    end

    it "does not offer to add seeds to a shelf that is not a crop" do
      expect(page).to have_no_link('+ add seeds')
    end
  end

  describe "searching" do
    let!(:brandywine_seed) { create(:seed, owner:, crop: brandywine) }
    let!(:cabbage_seed) { create(:seed, owner:, crop: cabbage) }

    context "when the search matches a parent crop" do
      before { visit member_seeds_path(owner, q: 'tomato') }

      it "finds seeds of its varieties" do
        expect(page).to have_css('.seed-card', text: /brandywine tomato/i)
      end

      it "leaves out other crops" do
        expect(page).to have_no_css('.seed-card', text: 'cabbage')
      end

      it "says how many packets it found" do
        expect(page).to have_css('.seed-search-summary', text: '1 packet of tomato seeds')
      end
    end

    context "when the search matches a variety" do
      before { visit member_seeds_path(owner, q: 'brandy') }

      it { expect(page).to have_css('.seed-card', text: /brandywine tomato/i) }
    end

    context "when nothing matches" do
      before { visit member_seeds_path(owner, q: 'leek') }

      it "says there are no seeds of that crop" do
        expect(page).to have_css('.seed-none h2', text: "No leek seeds from #{owner}")
      end

      it "offers everyone's seeds of it" do
        expect(page).to have_link('See leek seeds from everyone', href: seeds_path(q: 'leek'))
      end
    end

    context "when the only match is finished" do
      let!(:leek_seed) { create(:seed, owner:, crop: create(:crop, name: 'leek'), finished: true) }

      before { visit member_seeds_path(owner, q: 'leek') }

      it "points to the finished tab" do
        expect(page).to have_content('There are 1 finished')
      end
    end
  end

  describe "opening a stack" do
    let!(:seeds) { create_list(:seed, 3, owner:, crop: brandywine) }

    context "when closed" do
      before { visit member_seeds_path(owner) }

      it "offers to open the stack" do
        expect(page).to have_link('3 packets ▸ open')
      end

      it "shows only the top packet" do
        expect(page).to have_css('.seed-card', count: 1)
      end
    end

    context "when open" do
      before do
        visit member_seeds_path(owner)
        click_link '3 packets ▸ open'
      end

      it "shows every packet" do
        expect(page).to have_css('.seed-stack-panel .seed-card', count: 3)
      end

      it "links to the variety's page" do
        expect(page).to have_link('Open the Brandywine tomato page →', href: crop_path(brandywine))
      end

      it "closes again" do
        click_link 'Close ▴'
        expect(page).to have_no_css('.seed-stack-panel')
      end
    end
  end
end
