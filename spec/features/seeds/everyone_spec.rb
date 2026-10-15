# frozen_string_literal: true

require 'rails_helper'

describe "everyone's seeds", :js do
  let(:gardener) { create(:member, login_name: 'alex') }
  let(:other_gardener) { create(:member, login_name: 'mere') }
  let(:tomato) { create(:crop, name: 'tomato') }

  describe "which seeds are listed" do
    before do
      create(:seed, owner: gardener, crop: tomato, tradable_to: 'locally')
      create(:seed, owner: other_gardener, crop: create(:crop, name: 'cabbage'), tradable_to: 'nowhere')
      visit seeds_path
    end

    it { expect(page).to have_css('.seed-packet', count: 1) }
    it { expect(page).to have_css('.seed-packet', text: /tomato/i) }
  end

  describe "page header" do
    before do
      create(:seed, owner: gardener, crop: tomato, tradable_to: 'locally')
      create(:seed, owner: other_gardener, crop: tomato, tradable_to: 'nationally')
      visit seeds_path
    end

    it { expect(page).to have_css('h1', text: 'Seeds') }
    it { expect(page).to have_content('Seeds that gardeners have chosen to share') }
    it { expect(page).to have_css('.seed-tip', text: '2 packets from 2 gardeners.') }
    it { expect(page).to have_css('.seed-shelf-bar small', text: '2 packets · 2 gardeners') }
  end

  describe "who a packet belongs to" do
    before do
      create(:seed, owner: gardener, crop: tomato, tradable_to: 'locally')
      create(:seed, owner: other_gardener, crop: tomato, tradable_to: 'locally')
      visit seeds_path
    end

    it { expect(page).to have_css('.seed-owner', count: 2) }
    it { expect(page).to have_link(href: member_path(gardener), class: 'seed-owner') }
    it { expect(page).to have_css("a.seed-owner[title*='alex']") }
    it { expect(page).to have_no_text('see who') }
  end

  describe "several packets from one gardener" do
    before do
      create_list(:seed, 2, owner: gardener, crop: tomato, tradable_to: 'locally')
      create(:seed, owner: other_gardener, crop: tomato, tradable_to: 'locally')
      visit seeds_path
    end

    it { expect(page).to have_css('.seed-stack', count: 1) }
    it { expect(page).to have_css('.seed-stack-count', text: '×2') }
    it { expect(page).to have_css('.seed-owner', count: 2) }
  end

  describe "opening one gardener's stack" do
    before do
      create_list(:seed, 2, owner: gardener, crop: tomato, tradable_to: 'locally')
      visit seeds_path
      click_button 'tomato, 2 packets. Open to see each packet'
    end

    it { expect(page).to have_css('.seed-group .seed-group-packet', count: 2) }
    it { expect(page).to have_css('.seed-group-owner', text: 'by alex') }
  end

  describe "a variety the member already has" do
    include_context 'signed in member'

    before do
      create(:seed, owner: member, crop: tomato, tradable_to: 'nowhere')
      create(:seed, owner: gardener, crop: tomato, tradable_to: 'locally')
      visit seeds_path
    end

    it { expect(page).to have_css('.seed-have-it', text: 'You have it') }
  end

  describe "choosing whose seeds" do
    include_context 'signed in member'

    before do
      create(:seed, owner: gardener, crop: tomato, tradable_to: 'locally')
      create(:seed, owner: other_gardener, crop: create(:crop, name: 'cabbage'), tradable_to: 'locally')
      create(:follow, follower: member, followed: gardener)
      visit seeds_path(scope: 'following')
    end

    it { expect(page).to have_css('.seed-packet', text: /tomato/i) }
    it { expect(page).to have_no_css('.seed-packet', text: /cabbage/i) }
    it { expect(page).to have_css('.seed-scope a.active', text: 'People I follow') }
  end

  describe "distance chips" do
    context "when signed in with a location" do
      include_context 'signed in member'

      before do
        member.update!(location: 'Greenwich, UK', latitude: 51.483, longitude: -0.004)
        visit seeds_path
      end

      it { expect(page).to have_link('Within 50 km') }
      it { expect(page).to have_link('Within 10 km') }
    end

    context "when signed out" do
      before { visit seeds_path }

      it { expect(page).to have_no_link('Within 50 km') }
      it { expect(page).to have_link('Anywhere') }
    end
  end
end
