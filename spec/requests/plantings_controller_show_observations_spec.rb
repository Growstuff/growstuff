# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show observations' do
  let(:planting) { create(:planting, planted_at: Date.new(2026, 1, 1)) }
  let(:page) { Capybara.string(response.body) }

  context 'with none' do
    before { get planting_path(planting) }

    it { expect(page).to have_css('#observations', text: 'Nothing noticed yet') }
  end

  context 'with some' do
    before do
      create(:observation, planting: planting, kind: 'flowering', observed_at: Time.zone.local(2026, 2, 1, 9))
      create(:observation, planting: planting, kind: 'disease_observed', observed_at: Time.zone.local(2026, 3, 1, 9),
                           description: 'White spots on the leaves')
      create(:observation, planting: planting, kind: nil, observed_at: Time.zone.local(2026, 3, 2, 9))
      get planting_path(planting)
    end

    it 'lists them newest first, with the day of the planting' do
      expect(page).to have_css('.observation-timeline .observation', count: 3)
      expect(page.all('.observation-kind').map(&:text)).to eq ['Other', 'Disease observed', 'Flowering']
      expect(page).to have_css('.observation-problem', text: 'White spots on the leaves')
      expect(page).to have_css('.observation-day', text: 'Day 59')
      expect(page).to have_css('.observation-problem .observation-icon .fa-bug')
      expect(page).to have_css('.observation .observation-icon .fa-spa')
      expect(page).to have_css('.observation .observation-icon .fa-circle-question')
    end

    it 'gives the public no way to add or delete' do
      expect(page).to have_no_css('.observation-edit')
      expect(page).to have_no_css('.observation-delete')
      expect(page).to have_no_css('[data-planting-dialog="observation"]')
    end
  end

  context 'when signed in as the owner' do
    before do
      create(:observation, planting: planting)
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'offers to add, edit and delete' do
      expect(page).to have_css('[data-planting-dialog="observation"]')
      expect(page).to have_css('.observation-edit')
      expect(page).to have_css('.observation-delete')
    end
  end
end
