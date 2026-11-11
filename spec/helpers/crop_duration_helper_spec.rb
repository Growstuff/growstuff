# frozen_string_literal: true

require 'rails_helper'

describe CropDurationHelper do
  let(:crop) { create(:crop, growing_degree_days: 600) }
  let(:member) { nil }

  def facts
    helper.crop_duration_facts(crop, member)
  end

  context 'when signed out' do
    it('asks them to log in') { expect(facts[:hint]).to eq :sign_in }
    it('gives no days without a figure') { expect(facts[:days]).to be_nil }
  end

  context 'with a member who has set no location' do
    let(:member) { create(:member) }

    it('asks them to set a location') { expect(facts[:hint]).to eq :set_location }
  end

  context 'with a member whose place has no weather yet' do
    let(:member) do
      create(:member).tap do |each|
        each.update_columns(location: 'Wellington, New Zealand', latitude: -41.3, longitude: 174.7) # rubocop:disable Rails/SkipsModelValidations
      end
    end

    it('says the weather is not held yet') { expect(facts[:hint]).to eq :no_climate }
  end

  context 'with a crop with no degree days or other figures' do
    let(:crop) { create(:crop) }

    it('says nothing') { expect(facts).to be_nil }
  end

  context 'with a crop that has a median and no degree days' do
    let(:crop) { create(:crop, median_days_to_first_harvest: 70) }

    it('gives the median as the days') { expect(facts).to include(days: '70 days', source: :median, hint: nil) }
  end
end
