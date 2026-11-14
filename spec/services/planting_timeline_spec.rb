# frozen_string_literal: true

require 'rails_helper'

describe PlantingTimeline do
  subject(:timeline) { described_class.new(planting, today:) }

  let(:today) { Date.new(2026, 6, 1) }
  let(:planted_at) { Date.new(2026, 5, 1) }
  let(:planted_from) { 'seed' }
  let(:planting) { build(:planting, planted_at:, planted_from:) }
  let(:first_harvest) { nil }
  let(:last_harvest) { nil }
  let(:finish) { nil }

  before do
    allow(planting).to receive_messages(first_harvest_date: nil, first_harvest_predicted_at: first_harvest,
                                        last_harvest_predicted_at: last_harvest, finish_predicted_at: finish)
  end

  def kinds
    timeline.events.map(&:kind)
  end

  context 'when only planted' do
    it 'has nothing worth drawing' do
      expect(timeline).not_to be_show
    end
  end

  context 'with predictions for the whole life' do
    let(:first_harvest) { Date.new(2026, 7, 1) }
    let(:last_harvest) { Date.new(2026, 8, 1) }
    let(:finish) { Date.new(2026, 8, 31) }

    it 'lists the events in order, all but the sowing expected' do
      expect(kinds).to eq %i(sown first_harvest last_harvest finished)
      expect(timeline.events.map(&:expected)).to eq [false, true, true, true]
    end

    it 'runs the line from planting to the finish' do
      expect([timeline.start, timeline.finish]).to eq [planted_at, finish]
      expect(timeline).to be_show
    end

    it 'places an event by its share of the line' do
      expect(timeline.position(first_harvest)).to eq 50.0 # 61 of 122 days
      expect(timeline.position(planted_at)).to eq 0
      expect(timeline.position(finish)).to eq 100
    end

    it 'puts today along the line' do
      expect(timeline.today_position).to eq 25.41 # 31 of 122 days
    end
  end

  context 'when the predicted finish comes before the predicted harvests' do
    let(:first_harvest) { Date.new(2026, 7, 1) }
    let(:last_harvest) { Date.new(2026, 8, 1) }
    let(:finish) { Date.new(2026, 6, 20) }

    it 'moves the finish to the last harvest, so nothing comes after it' do
      expect(kinds).to eq %i(sown first_harvest last_harvest finished)
      expect(timeline.events.last.date).to eq last_harvest
    end
  end

  context 'when the predicted last harvest comes before the first' do
    let(:first_harvest) { Date.new(2026, 8, 1) }
    let(:last_harvest) { Date.new(2026, 7, 1) }
    let(:finish) { Date.new(2026, 9, 1) }

    it 'draws one harvest, as the last is not before the first' do
      expect(kinds).to eq %i(sown first_harvest finished)
    end
  end

  context 'when it was not started from seed' do
    let(:planted_from) { 'seedling' }

    it 'says planted, not sown' do
      expect(kinds).to eq %i(planted)
    end
  end

  context 'when it was moved to another garden' do
    let(:first_harvest) { Date.new(2026, 7, 1) }
    let(:garden) { create(:garden) }

    before do
      allow(planting).to receive(:histories).and_return([instance_double(PlantingHistory, ended_on: Date.new(2026, 5, 15),
                                                                                          moved_to: garden)])
    end

    it 'has the move, with where it went, between the sowing and the harvest' do
      expect(kinds).to eq %i(sown transplanted first_harvest)
      expect(timeline.events[1].garden).to eq garden
      expect(timeline.events[1].expected).to be false
    end
  end

  context 'when it has finished' do
    let(:today) { Date.new(2026, 8, 1) }
    let(:first_harvest) { Date.new(2026, 6, 20) }

    before do
      planting.finished = true
      planting.finished_at = Date.new(2026, 7, 10)
      allow(planting).to receive_messages(first_harvest_date: Date.new(2026, 6, 20), last_harvest_date: Date.new(2026, 7, 5))
    end

    it 'has the harvests and finish as they happened, and no marker for today' do
      expect(timeline.events.map(&:expected)).to eq [false, false, false, false]
      expect(kinds).to eq %i(sown first_harvest last_harvest finished)
      expect(timeline.today_position).to be_nil
      expect(timeline.finish).to eq Date.new(2026, 7, 10)
    end
  end

  context 'when it failed' do
    before do
      planting.failed = true
      planting.finished = true
      planting.finished_at = Date.new(2026, 5, 20)
    end

    it 'ends in a failure' do
      expect(kinds).to eq %i(sown failed)
    end
  end

  context 'when the last harvest falls on the first' do
    let(:first_harvest) { Date.new(2026, 7, 1) }
    let(:last_harvest) { Date.new(2026, 7, 1) }

    it 'draws one harvest, not two on top of each other' do
      expect(kinds).to eq %i(sown first_harvest)
    end
  end

  context 'when it is past its predicted finish and still going' do
    let(:finish) { Date.new(2026, 5, 20) }

    it 'runs the line to today' do
      expect(timeline.finish).to eq today
    end
  end
end
