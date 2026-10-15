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
end
