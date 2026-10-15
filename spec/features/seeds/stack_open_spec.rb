# frozen_string_literal: true

require 'rails_helper'

describe "opening a stack of packets", :js do
  let(:owner) { create(:member) }
  let(:crop) { create(:crop, name: 'Brandywine tomato') }
  let(:pile_button) { 'Brandywine tomato, 3 packets. Open to see each packet' }

  context "when viewing someone else's seeds" do
    before do
      create_list(:seed, 3, owner:, crop:)
      visit member_seeds_path(owner)
    end

    context "when closed" do
      it { expect(page).to have_button(pile_button) }
      it { expect(page).to have_css('.seed-packet', count: 1) }
    end

    context "when opened" do
      before { click_button pile_button }

      it { expect(page).to have_css('.seed-group .seed-group-packet', count: 3) }
      it { expect(page).to have_link('View', count: 3) }
      it { expect(page).to have_link('Open the Brandywine tomato page →', href: crop_path(crop)) }
      it { expect(page).to have_current_path member_seeds_path(owner), ignore_query: true }
      it { expect(page).to have_no_link('Edit') }
    end

    context "when closed again" do
      before do
        click_button pile_button
        click_button 'Close ▴'
      end

      it { expect(page).to have_no_css('.seed-group') }
      it { expect(page).to have_button(pile_button) }
    end

    context "when closed with the escape key" do
      before do
        click_button pile_button
        find_button('Close ▴').send_keys(:escape)
      end

      it { expect(page).to have_no_css('.seed-group') }
    end
  end

  context "when viewing your own seeds" do
    include_context 'signed in member'

    before do
      create_list(:seed, 3, owner: member, crop:)
      visit member_seeds_path(member)
      click_button pile_button
    end

    it { expect(page).to have_link('Edit', count: 3) }
  end
end
