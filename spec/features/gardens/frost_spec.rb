# frozen_string_literal: true

require 'rails_helper'

describe 'Frost on a garden', flipper: :planting_weather do
  let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations

  let(:threshold) { FrostCalculator::FROST_DANGER_C }

  context 'with frost dates for the garden' do
    before do
      create(:frost_stat, threshold_c: threshold)
      visit garden_path(garden)
    end

    it { expect(page).to have_css '.frost-section .frost-timeline' }
    it { expect(page).to have_no_css '.frost-band--so_far' }
  end

  context 'without frost dates' do
    before { visit garden_path(garden) }

    it { expect(page).to have_no_css '.frost-section' }
  end

  context 'when the feature is switched off', flipper: [] do
    before do
      create(:frost_stat, threshold_c: threshold)
      visit garden_path(garden)
    end

    it { expect(page).to have_no_css '.frost-section' }
  end
end
