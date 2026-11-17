# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, '#show observations' do
  include ActiveSupport::Testing::TimeHelpers

  let(:planting) { create(:planting, planted_at: Date.new(2026, 1, 1)) }
  let(:page) { Capybara.string(response.body) }

  context 'with none' do
    before { get planting_path(planting) }

    it 'offers the public nothing to log' do
      expect(page).to have_no_css('#observations .notepad-ideas')
    end

    it { expect(page).to have_css('#observations .observation-planted', text: 'Planted') }
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
      expect(page).to have_css('.observation-timeline .observation', count: 4)
      expect(page.all('.observation-kind').map(&:text)).to eq ['Other', 'Disease observed', 'Flowering', 'Planted']
      expect(page).to have_css('.observation-problem', text: 'White spots on the leaves')
      expect(page).to have_css('.observation-day', text: 'Day 59')
      expect(page).to have_css('.observation-problem .observation-icon .fa-bug')
      expect(page).to have_css('.observation .observation-icon .fa-spa')
      expect(page).to have_css('.observation .observation-icon .fa-circle-question')
    end

    it 'ends with the planting, which cannot be edited' do
      expect(page).to have_css('.observation-timeline .observation-planted:last-child', text: 'Planted')
      expect(page).to have_css('.observation-planted .observation-day', text: 'Day 0')
    end

    it 'gives the public no way to add or delete' do
      expect(page).to have_no_css('.observation-edit')
      expect(page).to have_no_css('.observation-delete')
      expect(page).to have_no_css('[data-planting-dialog="observation"]')
    end
  end

  context 'with a harvest' do
    before do
      create(:harvest, planting:, crop: planting.crop, owner: planting.owner, harvested_at: Date.new(2026, 1, 11))
      get planting_path(planting)
    end

    it 'lists it on the timeline, with the day of the planting' do
      expect(page).to have_css('.observation-harvest .observation-day', text: 'Day 10')
    end

    it 'links to the harvest' do
      expect(page).to have_css('.observation-harvest a[href^="/harvests/"]')
    end

    it 'no longer has a section of its own' do
      expect(page).to have_no_css('section#harvests')
    end

    it 'gives the public no way to edit it' do
      expect(page).to have_no_css('.observation-harvest .harvest-edit')
    end
  end

  context 'with a harvest, when signed in as the owner' do
    before do
      create(:harvest, planting:, crop: planting.crop, owner: planting.owner, harvested_at: Date.new(2026, 1, 11))
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'offers to edit it' do
      expect(page).to have_css('.observation-harvest .harvest-edit[href$="/edit"]')
    end
  end

  context 'with a move out of the nursery' do
    before do
      nursery = create(:garden, owner: planting.owner).tap(&:make_nursery!)
      create(:planting_history, planting:, garden: nursery, started_on: Date.new(2026, 1, 1), ended_on: Date.new(2026, 1, 11))
      get planting_path(planting)
    end

    it 'lists the day it moved, with the day of the planting' do
      expect(page).to have_css('.observation-transplanted .observation-day', text: 'Day 10')
    end

    it 'names the garden it moved into' do
      expect(page).to have_css(".observation-transplanted a[href='/gardens/#{planting.garden.slug}']", text: planting.garden.name)
    end
  end

  context 'with jobs' do
    before do
      create(:job, jobbable: planting, owner: planting.owner, name: 'Mulch the bed', finished: true)
        .update_columns(finished_at: Time.zone.local(2026, 1, 6, 10)) # rubocop:disable Rails/SkipsModelValidations
      create(:job, jobbable: planting, owner: planting.owner, name: 'Water in', finished: false)
      get planting_path(planting)
    end

    it 'lists the one that is done on the timeline, with the day of the planting' do
      expect(page).to have_css('.observation-job .observation-day', text: 'Day 5')
    end

    it 'names it' do
      expect(page).to have_css('.observation-job', text: 'Mulch the bed')
    end

    it 'leaves the one still to do in the jobs section' do
      expect(page).to have_css('#jobs', text: 'Water in')
    end

    it 'takes the one that is done out of the jobs section' do
      expect(page).to have_no_css('#jobs', text: 'Mulch the bed')
    end
  end

  context 'with frost dates for the place', flipper: :planting_weather do
    let(:garden) { create(:garden).tap { |g| g.update_columns(latitude: -41.29, longitude: 174.78) } } # rubocop:disable Rails/SkipsModelValidations
    let(:planting) { create(:planting, garden:, owner: garden.owner, planted_at: Date.new(2026, 8, 18)) }
    let(:cell) { planting.weather_cell }

    before do
      travel_to(Time.zone.local(2026, 11, 7, 12))
      create(:frost_stat, latitude: cell.first, longitude: cell.last, threshold_c: FrostCalculator::FROST_DANGER_C, status: 'frost',
                          first_frost_p10: 154, first_frost_median: 173, last_frost_median: 240, last_frost_p90: 273)
      get planting_path(planting)
    end

    it 'marks the day the frost danger passed, with the day of the planting' do
      expect(page).to have_css('.observation-frost .observation-day', text: 'Day 44')
    end
  end

  context 'with days too cold and too hot for the crop' do
    before do
      [2, 3].each do |day|
        create(:planting_condition, planting:, kind: 'killing_cold', occurred_on: Date.new(2026, 1, day), value: -4.0, threshold: -2.0)
      end
      create(:planting_condition, planting:, kind: 'killing_heat', occurred_on: Date.new(2026, 1, 9), value: 41.0, threshold: 38.0)
      get planting_path(planting)
    end

    it 'lists the cold days as one entry, with the coldest' do
      expect(page).to have_css('.observation-problem', text: 'Too cold for 2 days in a row Down to -4 °C, at or below the -2 °C')
    end

    it 'lists the hot day' do
      expect(page).to have_css('.observation-problem', text: 'Too hot Up to 41 °C, above the 38 °C')
    end
  end

  context 'with heavy rain, extreme heat and first snow' do
    before do
      create(:planting_condition, planting:, kind: 'heavy_rain', occurred_on: Date.new(2026, 1, 8), value: 112.0, threshold: 100.0)
      create(:planting_condition, planting:, kind: 'extreme_heat', occurred_on: Date.new(2026, 1, 9), value: 41.3, threshold: 40.0)
      create(:planting_condition, planting:, kind: 'first_snow', occurred_on: Date.new(2026, 1, 10), value: 3.0)
      get planting_path(planting)
    end

    it 'lists the heavy rain with how much fell' do
      expect(page).to have_css('.observation-problem', text: 'Heavy rain 112 mm of rain in a day.')
    end

    it 'lists the extreme heat with the high, on the heat tint' do
      expect(page).to have_css('.observation-hot', text: 'Extreme heat A high of 41.3 °C.')
    end

    it 'lists the first snow of the winter' do
      expect(page).to have_css('.observation-frost', text: 'First snow of the winter 3 cm of snow fell.')
    end
  end

  context 'with a day of damaging wind' do
    before do
      create(:planting_condition, planting:, kind: 'damaging_wind', occurred_on: Date.new(2026, 1, 9), value: 104.0, threshold: 90.0,
                                  direction_degrees: 180.0, temp_min_c: 11.1, temp_max_c: 13.7)
      get planting_path(planting)
    end

    it 'lists it with the gusts, where from and the temperatures' do
      expect(page).to have_css('.observation-problem', text: 'Damaging wind Gusts up to 104 km/h from the south, 11.1 to 13.7 °C that day.')
    end
  end

  context 'with a finished job, when signed in as the owner' do
    before do
      create(:job, jobbable: planting, owner: planting.owner, finished: true)
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'gives it no menu on the timeline' do
      expect(page).to have_no_css('.observation-job .observation-actions')
    end
  end

  context 'with frost on three nights in a row' do
    before do
      [2, 3, 4].each { |day| create(:planting_condition, planting:, occurred_on: Date.new(2026, 1, day), value: day - 5.0) }
      get planting_path(planting)
    end

    it 'lists them as one entry, with the coldest' do
      expect(page).to have_css('.observation-frost', count: 1, text: 'Frost detected for 3 nights in a row')
      expect(page).to have_css('.observation-frost .observation-note', text: 'Overnight temperature fell to -3 °C')
    end

    it 'dates it from the first night' do
      expect(page).to have_css('.observation-frost .observation-day', text: 'Day 1')
    end

    it 'gives it no way to edit' do
      expect(page).to have_no_css('.observation-frost .observation-edit')
    end
  end

  context 'when signed in as the owner with none' do
    before do
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'suggests logging one, opening the dialog' do
      expect(page).to have_css('#observations .notepad-ideas[data-planting-dialog="observation"]')
    end
  end

  context 'when signed in as the owner with some' do
    before do
      create(:observation, planting: planting)
      sign_in planting.owner
      get planting_path(planting)
    end

    it 'does not suggest logging one' do
      expect(page).to have_no_css('#observations .notepad-ideas')
    end

    it 'offers to add, edit and delete' do
      expect(page).to have_css('[data-planting-dialog="observation"]')
      expect(page).to have_css('.observation-edit')
      expect(page).to have_css('.observation-delete')
    end
  end
end
