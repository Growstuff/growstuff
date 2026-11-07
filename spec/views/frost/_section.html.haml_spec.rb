# frozen_string_literal: true

require 'rails_helper'

describe 'frost/_section' do
  let(:reading) { Struct.new(:date, :temp_min_c) }
  let(:stat) do
    build(:frost_stat, status: 'frost', first_frost_p10: 154, first_frost_median: 173, last_frost_median: 240, last_frost_p90: 273)
  end
  let(:finished) { false }
  let(:today) { Date.new(2026, 11, 7) }
  let(:frost) do
    PlantingFrost.new(stat:, planted_on: Date.new(2026, 8, 18), ends_on: Date.new(2027, 2, 16), finished:,
                      readings: [reading.new(Date.new(2026, 8, 20), 3.3)], today:)
  end

  before { render partial: 'frost/section', locals: { frost: } }

  it 'shows the verdict' do
    expect(rendered).to have_css '.frost-verdict--passed'
  end

  it 'draws the timeline' do
    expect(rendered).to have_css '.frost-timeline .frost-band--usual'
  end

  it 'shows the figures' do
    expect(rendered).to have_css '.frost-card', count: 4
  end

  it 'marks the section experimental' do
    expect(rendered).to have_css '.frost-section-badge[href="#about-frost-estimates"]'
  end

  context 'when the planting has finished' do
    let(:finished) { true }

    it 'shows the finished verdict' do
      expect(rendered).to have_css '.frost-verdict--finished_clear'
    end

    it 'draws the planting as one bar' do
      expect(rendered).to have_css '.frost-band--finished'
    end
  end

  context 'when frost is rare' do
    let(:stat) do
      build(:frost_stat, status: 'rare', first_frost_median: nil, last_frost_median: nil, first_frost_p10: nil, last_frost_p90: nil)
    end

    it 'shows the verdict' do
      expect(rendered).to have_css '.frost-verdict--rare'
    end

    it 'leaves out the timeline' do
      expect(rendered).to have_no_css '.frost-timeline'
    end

    it 'leaves out the figures' do
      expect(rendered).to have_no_css '.frost-card'
    end
  end

  context 'with a garden, which has no planting' do
    let(:frost) { FrostSeason.new(stat:, today:) }

    it 'shows the verdict' do
      expect(rendered).to have_css '.frost-verdict--passed'
    end

    it 'draws the frost danger' do
      expect(rendered).to have_css '.frost-timeline .frost-band--usual'
    end

    it 'leaves out the planting row' do
      expect(rendered).to have_no_css '.frost-band--so_far'
    end

    it 'shows the figures about the place' do
      expect(rendered).to have_css '.frost-card', count: 3
    end
  end
end
