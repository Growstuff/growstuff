# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#index' do
  let(:planting) { create(:planting) }
  let(:owner) { planting.owner }
  let(:page) { Capybara.string(response.body) }

  context 'when viewing your own member plantings list' do
    before do
      sign_in owner
      get member_plantings_path(owner)
    end

    it 'shows the planting short code' do
      expect(page).to have_css('.card.planting .planting-short-code', text: planting.short_code)
    end
  end

  context 'when viewing another member’s plantings list' do
    before do
      sign_in create(:member)
      get member_plantings_path(owner)
    end

    it 'does not show short codes' do
      expect(page).to have_no_css('.planting-short-code')
    end
  end

  context 'when viewing a member’s plantings list without signing in' do
    before { get member_plantings_path(owner) }

    it 'does not show short codes' do
      expect(page).to have_no_css('.planting-short-code')
    end
  end

  context 'when viewing the general plantings list as an owner' do
    before do
      sign_in owner
      get plantings_path
    end

    it 'does not show short codes' do
      expect(page).to have_no_css('.planting-short-code')
    end
  end
end
