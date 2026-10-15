# frozen_string_literal: true

require 'rails_helper'

describe "seed filters" do
  let(:owner) { create(:member) }
  let(:tomato) { create(:crop, name: 'tomato') }
  let(:brandywine) { create(:crop, name: 'Brandywine tomato', parent: tomato) }
  let(:cabbage) { create(:crop, name: 'cabbage') }

  describe "in stock and finished tabs" do
    before do
      create(:seed, owner:, crop: tomato)
      create(:seed, owner:, crop: cabbage, finished: true)
    end

    context "without choosing a tab" do
      before { visit member_seeds_path(owner) }

      it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
      it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
      it { expect(page).to have_link('Finished 1') }
    end

    context "when on the finished tab" do
      before do
        visit member_seeds_path(owner)
        click_link 'Finished'
      end

      it { expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage') }
      it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'tomato') }
    end
  end

  describe "searching" do
    before do
      create(:seed, owner:, crop: brandywine)
      create(:seed, owner:, crop: cabbage)
    end

    context "when the search matches a parent crop" do
      before { visit member_seeds_path(owner, q: 'tomato') }

      it { expect(page).to have_css('.seed-packet', text: /brandywine tomato/i) }
      it { expect(page).to have_no_css('.seed-packet', text: /cabbage/i) }
      it { expect(page).to have_css('.seed-search-summary', text: '1 packet of tomato seeds') }
    end

    context "when the search matches a variety" do
      before { visit member_seeds_path(owner, q: 'brandy') }

      it { expect(page).to have_css('.seed-packet', text: /brandywine tomato/i) }
    end

    context "when nothing matches" do
      before { visit member_seeds_path(owner, q: 'leek') }

      it { expect(page).to have_css('.seed-none h2', text: "No leek seeds from #{owner}") }
      it { expect(page).to have_link('See leek seeds from everyone', href: seeds_path(q: 'leek')) }
    end

    context "when the only match is finished" do
      before do
        create(:seed, owner:, crop: create(:crop, name: 'leek'), finished: true)
        visit member_seeds_path(owner, q: 'leek')
      end

      it { expect(page).to have_content('1 more finished') }
    end
  end

  describe "source chips" do
    before do
      create(:seed, owner:, crop: tomato, source: 'my own seed saving')
      create(:seed, owner:, crop: cabbage, source: 'retail outlet')
    end

    context "when choosing my own saving" do
      before { visit member_seeds_path(owner, from: 'own') }

      it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
      it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
      it { expect(page).to have_css('.seed-chip.active', text: 'My own saving') }
    end

    context "when choosing bought" do
      before { visit member_seeds_path(owner, from: 'bought') }

      it { expect(page).to have_css('.seed-shelf-bar h3', text: 'cabbage') }
      it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'tomato') }
    end
  end

  describe "past sow-by banner" do
    context "with a packet past its sow-by year" do
      before do
        create(:seed, owner:, crop: tomato, plant_before: Date.new(2020, 12, 31))
        create(:seed, owner:, crop: cabbage, plant_before: 2.years.from_now.to_date)
      end

      context "when showing everything" do
        before { visit member_seeds_path(owner) }

        it { expect(page).to have_css('.seed-tip', text: '1 packet is past their sow-by date') }
        it { expect(page).to have_link('Show me that one', href: member_seeds_path(owner, past: 1)) }
      end

      context "when showing only those past it" do
        before { visit member_seeds_path(owner, past: 1) }

        it { expect(page).to have_css('.seed-shelf-bar h3', text: 'tomato') }
        it { expect(page).to have_no_css('.seed-shelf-bar h3', text: 'cabbage') }
        it { expect(page).to have_link('Show all') }
      end
    end

    context "with every packet in date" do
      before do
        create(:seed, owner:, crop: tomato, plant_before: 2.years.from_now.to_date)
        visit member_seeds_path(owner)
      end

      it { expect(page).to have_no_css('.seed-tip') }
    end
  end

  describe "when nothing is shown" do
    context "with no seeds at all" do
      before { visit member_seeds_path(owner) }

      it { expect(page).to have_css('.seed-empty', text: 'No seeds recorded yet') }
    end

    context "with a filter hiding every seed" do
      before do
        create(:seed, owner:, crop: tomato, source: 'retail outlet')
        visit member_seeds_path(owner, from: 'own')
      end

      it { expect(page).to have_css('.seed-empty', text: 'No seeds match those filters.') }
      it { expect(page).to have_link('Show all seeds') }
    end

    context "on the finished tab with none finished" do
      before do
        create(:seed, owner:, crop: tomato)
        visit member_seeds_path(owner, finished: 1)
      end

      it { expect(page).to have_css('.seed-empty', text: 'No finished seeds yet.') }
    end
  end

  describe "whose seeds" do
    include_context 'signed in member'

    before { visit member_seeds_path(member) }

    it { expect(page).to have_css('.seed-scope a.active', text: 'Mine') }
    it { expect(page).to have_link('People I follow', href: seeds_path(scope: 'following')) }
    it { expect(page).to have_link('Near me', href: seeds_path(scope: 'near')) }
    it { expect(page).to have_link('Everyone', href: seeds_path) }
  end

  describe "whose seeds when signed out" do
    before { visit member_seeds_path(owner) }

    it { expect(page).to have_no_css('.seed-scope') }
  end
end
