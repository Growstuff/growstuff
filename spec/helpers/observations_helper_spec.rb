# frozen_string_literal: true

require 'rails_helper'

describe ObservationsHelper do
  describe '#observation_timeline' do
    subject(:timeline) { helper.observation_timeline(planting, observations, conditions:, harvests:, jobs:, frost_passed_on:) }

    let(:planting) { create(:planting, planted_at: Date.new(2026, 5, 1)) }
    let(:harvests) { [] }
    let(:jobs) { [] }
    let(:frost_passed_on) { nil }
    let(:observations) { [build(:observation, planting:, observed_at: Time.zone.local(2026, 5, 3, 9))] }
    let(:conditions) { [build(:planting_condition, planting:, occurred_on: Date.new(2026, 5, 2))] }

    it 'lists the newest first' do
      expect(timeline.map(&:type)).to eq %i(observation frost planted)
    end

    context 'without conditions' do
      let(:conditions) { [] }

      it 'leaves them out' do
        expect(timeline.map(&:type)).to eq %i(observation planted)
      end
    end

    context 'with a frost night on the day it was planted' do
      let(:conditions) { [build(:planting_condition, planting:, occurred_on: Date.new(2026, 5, 1))] }

      it 'puts the frost above the planting' do
        expect(timeline.map(&:type)).to eq %i(observation frost planted)
      end
    end

    context 'with a harvest' do
      let(:harvests) { [build(:harvest, planting:, harvested_at: Date.new(2026, 5, 2))] }

      it 'puts it in order by the day it was picked' do
        expect(timeline.map(&:type)).to eq %i(observation harvest frost planted)
      end
    end

    context 'with a job done' do
      let(:jobs) { [build(:job, finished: true, finished_at: Time.zone.local(2026, 5, 2, 15))] }

      it 'puts it in order by the day it was done' do
        expect(timeline.map(&:type)).to eq %i(observation job frost planted)
      end
    end

    context 'with the day frost danger passed, the same day as a frost night' do
      let(:frost_passed_on) { Date.new(2026, 5, 2) }

      it 'puts it above the night' do
        expect(timeline.map(&:type)).to eq %i(observation frost_passed frost planted)
      end
    end

    context 'with frost and killing cold on the same nights' do
      let(:conditions) do
        %w(frost killing_cold).flat_map do |kind|
          [2, 3].map { |day| build(:planting_condition, planting:, kind:, occurred_on: Date.new(2026, 5, day)) }
        end
      end

      it 'makes a run of each, not one broken up' do
        expect(timeline.select { |entry| entry.type.in?(%i(frost killing_cold)) }.map { |entry| entry.record.size }).to eq [2, 2]
      end
    end

    context 'with frost on three nights in a row and another later' do
      let(:conditions) do
        [2, 3, 4, 9].map { |day| build(:planting_condition, planting:, occurred_on: Date.new(2026, 5, day)) }
      end

      it 'makes one entry for each run of nights' do
        expect(timeline.select { |entry| entry.type == :frost }.map { |entry| entry.record.size }).to eq [1, 3]
      end
    end
  end
end
