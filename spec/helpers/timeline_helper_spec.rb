# frozen_string_literal: true

require 'rails_helper'

describe TimelineHelper do
  describe '#planted_note' do
    subject(:note) { helper.planted_note(planting) }

    let(:planting) { create(:planting, planted_at: Date.new(2026, 5, 1)) }

    it { is_expected.to be_nil }

    context 'when it is in the nursery' do
      let(:nursery) { create(:garden).tap(&:make_nursery!) }
      let(:planting) { create(:planting, garden: nursery, owner: nursery.owner) }

      it { is_expected.to eq 'Sown in the nursery.' }
    end

    context 'when it began in a nursery and has moved out' do
      before do
        nursery = create(:garden, owner: planting.owner).tap(&:make_nursery!)
        create(:planting_history, planting:, garden: nursery, ended_on: Date.new(2026, 6, 1))
      end

      it { is_expected.to eq 'Sown in the nursery.' }
    end

    context 'with a seed packet we have recorded' do
      let(:planting) { create(:planting, parent_seed: create(:seed)) }

      it 'says so and links to it' do
        expect(note).to have_link("a seed packet we've recorded", href: "/seeds/#{planting.parent_seed.slug}")
      end
    end

    context 'when started another way' do
      let(:planting) { create(:planting, planted_from: 'cutting') }

      it { is_expected.to eq 'Started as: cutting.' }
    end

    context 'with a seedling and where it came from' do
      let(:planting) { create(:planting, planted_from: 'seedling') }

      before { create(:planting_seedling, planting:, source: 'shop', supplier: 'Kiwi Seedlings') }

      it { is_expected.to eq 'Started as: seedling · Shop or garden centre · Kiwi Seedlings.' }
    end
  end

  describe '#weather_entry' do
    let(:planting) { build(:planting, crop: build(:crop, name: 'pea')) }

    context 'with damaging wind' do
      let(:run) do
        [build(:place_condition, kind: 'damaging_wind', value: 101.0, direction_degrees: 10.0, temp_min_c: 6.1, temp_max_c: 15.8),
         build(:place_condition, kind: 'damaging_wind', value: 112.4, direction_degrees: 225.0, temp_min_c: 8.0, temp_max_c: 14.0)]
      end

      it 'describes the strongest day, with where from and the temperatures' do
        expect(helper.weather_entry(:damaging_wind, run,
                                    planting)[:note]).to eq 'Gusts up to 112 km/h from the south-west, 8 to 14 °C that day.'
      end

      it 'says how many days in a row' do
        expect(helper.weather_entry(:damaging_wind, run, planting)[:title]).to eq 'Damaging wind for 2 days in a row'
      end

      it 'leaves out what is not known' do
        run.last.assign_attributes(direction_degrees: nil, temp_min_c: nil)
        expect(helper.weather_entry(:damaging_wind, run, planting)[:note]).to eq 'Gusts up to 112 km/h.'
      end
    end

    context 'with a day too cold for the crop' do
      let(:run) { [build(:planting_condition, kind: 'killing_cold', value: -4.0, threshold: -2.0)] }

      it 'names the crop and the limit it crossed' do
        expect(helper.weather_entry(:killing_cold, run, planting)[:note]).to eq 'Down to -4 °C, at or below the -2 °C that kills pea.'
      end

      it 'is a problem, in a cold icon' do
        expect(helper.weather_entry(:killing_cold, run, planting)).to include(icon: 'temperature-low', classes: 'observation-problem')
      end
    end
  end

  describe '#timeline_partial' do
    it 'shares one partial between the weather kinds' do
      expect(%i(frost killing_heat first_snow).map { |type| helper.timeline_partial(type) }).to eq %w(weather weather weather)
    end

    it 'names the others for themselves' do
      expect(helper.timeline_partial(:harvest)).to eq 'harvest'
    end
  end

  describe '#observation_timeline' do
    subject(:timeline) { helper.observation_timeline(planting, observations, conditions:, harvests:, jobs:, frost_passed_on:, histories:) }

    let(:planting) { create(:planting, planted_at: Date.new(2026, 5, 1)) }
    let(:harvests) { [] }
    let(:jobs) { [] }
    let(:frost_passed_on) { nil }
    let(:histories) { [] }
    let(:observations) { [build(:observation, planting:, observed_at: Time.zone.local(2026, 5, 3, 9))] }
    let(:conditions) { [build(:place_condition, occurred_on: Date.new(2026, 5, 2))] }

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
      let(:conditions) { [build(:place_condition, occurred_on: Date.new(2026, 5, 1))] }

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

    context 'with a move out of the nursery' do
      let(:nursery) { create(:garden, owner: planting.owner).tap(&:make_nursery!) }
      let(:histories) { [create(:planting_history, planting:, garden: nursery, ended_on: Date.new(2026, 5, 2))] }

      it 'puts it in order by the day it moved' do
        expect(timeline.map(&:type)).to eq %i(observation frost transplanted planted)
      end
    end

    context 'with a move out of an ordinary garden' do
      let(:histories) { [create(:planting_history, planting:, ended_on: Date.new(2026, 5, 2))] }

      it 'leaves it out' do
        expect(timeline.map(&:type)).to eq %i(observation frost planted)
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
        [2, 3].flat_map do |day|
          [build(:place_condition, kind: 'frost', occurred_on: Date.new(2026, 5, day)),
           build(:planting_condition, planting:, kind: 'killing_cold', occurred_on: Date.new(2026, 5, day))]
        end
      end

      it 'makes a run of each, not one broken up' do
        expect(timeline.select { |entry| entry.type.in?(%i(frost killing_cold)) }.map { |entry| entry.record.size }).to eq [2, 2]
      end
    end

    context 'with frost on three nights in a row and another later' do
      let(:conditions) do
        [2, 3, 4, 9].map { |day| build(:place_condition, occurred_on: Date.new(2026, 5, day)) }
      end

      it 'makes one entry for each run of nights' do
        expect(timeline.select { |entry| entry.type == :frost }.map { |entry| entry.record.size }).to eq [1, 3]
      end
    end
  end
end
