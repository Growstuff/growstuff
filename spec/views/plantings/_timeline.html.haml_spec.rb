# frozen_string_literal: true

require 'rails_helper'

describe 'plantings/_timeline' do
  let(:planting) { build(:planting, planted_at: Time.zone.today - 10, planted_from: 'seed', crop: build(:crop, perennial: false)) }

  before do
    allow(planting).to receive_messages(first_harvest_date: nil, first_harvest_predicted_at: Time.zone.today + 30,
                                        last_harvest_predicted_at: nil, finish_predicted_at: Time.zone.today + 60)
    render partial: 'plantings/timeline', locals: { planting: }
  end

  it 'lists the events, marking the expected ones' do
    expect(rendered).to have_css '.planting-timeline-event', count: 3
    expect(rendered).to have_css '.planting-timeline-event:not(.planting-timeline-event--expected) .planting-timeline-name', text: 'Sown'
    expect(rendered).to have_css '.planting-timeline-event--expected .planting-timeline-name', text: 'First harvest'
    expect(rendered).to have_css '.planting-timeline-event--expected .planting-timeline-name', text: 'Finished'
  end

  it 'gives each event its own icon' do
    expect(rendered).to have_css '.planting-timeline-event .planting-timeline-marker img[alt="planting"]'
    expect(rendered).to have_css '.planting-timeline-event .planting-timeline-marker img[alt="harvest"]'
    expect(rendered).to have_css '.planting-timeline-event .planting-timeline-marker img[alt="finish"]'
  end

  context 'when the garden has a place' do
    before do
      allow(planting).to receive(:latitude).and_return(-41.3)
      render partial: 'plantings/timeline', locals: { planting: }
    end

    it 'makes the line of the seasons it runs through, named' do
      expect(rendered).to have_css '.planting-timeline-line--seasons .weather-seasons span[class^="season-"]',
                                   text: /Spring|Summer|Autumn|Winter/
    end
  end

  context 'when the garden has no place' do
    before do
      allow(planting).to receive(:latitude).and_return(nil)
      render partial: 'plantings/timeline', locals: { planting: }
    end

    it 'is a plain line' do
      expect(rendered).to have_no_css '.weather-seasons'
      expect(rendered).to have_no_css '.planting-timeline-line--seasons'
    end
  end

  it 'puts today on the line' do
    expect(rendered).to have_css '.planting-timeline-today'
  end

  it 'has no row of emoji' do
    expect(rendered).to have_no_text 'One emoji'
  end

  context 'with nothing but the planting' do
    before do
      allow(planting).to receive_messages(first_harvest_predicted_at: nil, finish_predicted_at: nil)
      render partial: 'plantings/timeline', locals: { planting: }
    end

    it 'draws no line' do
      expect(rendered).to have_no_css '.planting-timeline-event', text: 'Finished'
    end
  end
end
