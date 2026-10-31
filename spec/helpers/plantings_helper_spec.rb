# frozen_string_literal: true

require 'rails_helper'

describe PlantingsHelper do
  describe "display_planting" do
    let!(:member) { build(:member, login_name: 'crop_lady') }

    it "does not have a quantity nor a planted from value provided" do
      planting = build(:planting,
                       quantity:     nil,
                       planted_from: '',
                       owner:        member)
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady planted magic bean."
    end

    it "does not have a quantity provided" do
      planting = build(:planting,
                       quantity:     nil,
                       planted_from: 'seed',
                       owner:        member)
      result = helper.display_planting(planting)
      expect(result).to eq "crop_lady planted seeds."
    end

    context "when quantity is greater than 1" do
      it "does not have a planted from value provided" do
        planting = build(:planting,
                         quantity:     10,
                         planted_from: '',
                         owner:        member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 10 units."
      end

      it "does have a planted from value provided" do
        planting = build(:planting,
                         quantity:     5,
                         planted_from: 'seed',
                         owner:        member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 5 seeds."
      end
    end

    context "when quantity is 1" do
      it "does not have a planted from value provided" do
        planting = build(:planting,
                         quantity:     1,
                         planted_from: '',
                         owner:        member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 unit."
      end

      it "does have a planted from value provided" do
        planting = build(:planting,
                         quantity:     1,
                         planted_from: 'seed',
                         owner:        member)
        result = helper.display_planting(planting)
        expect(result).to eq "crop_lady planted 1 seed."
      end
    end
  end

  describe '#weather_summary' do
    subject(:summary) { helper.weather_summary(readings) }

    let(:readings) do
      [build(:weather_reading, rainfall_mm: 2.0, temp_max_c: 15.0, temp_min_c: 8.0),
       build(:weather_reading, rainfall_mm: 3.5, temp_max_c: 19.0, temp_min_c: 6.0)]
    end

    it { expect(summary[:rain]).to eq '6 mm' }
    it { expect(summary[:hottest]).to eq '19.0°C' }
    it { expect(summary[:coldest]).to eq '6.0°C' }
    it { expect(summary[:days]).to eq 2 }

    it 'leaves out soil temperature when there is none' do
      expect(summary).not_to have_key(:soil_temp)
    end
  end

  describe '#weather_rain_chart' do
    let(:from) { Date.new(2026, 10, 1) }

    it 'draws a bar for each rainy day' do
      readings = [build(:weather_reading, date: from, rainfall_mm: 2.0), build(:weather_reading, date: from + 1, rainfall_mm: 0.0)]
      expect(helper.weather_rain_chart(readings, from:, days: 10).scan('<rect').size).to eq 1
    end

    it 'keeps a bar for the last day of the axis inside the chart' do
      readings = [build(:weather_reading, date: from + 3, rainfall_mm: 2.0)]
      expect(helper.weather_rain_chart(readings, from:, days: 4)).to include('x="450.0"', 'width="150.0"')
    end

    it 'places a bar by its date along the axis' do
      readings = [build(:weather_reading, date: from + 5, rainfall_mm: 2.0)]
      expect(helper.weather_rain_chart(readings, from:, days: 10)).to include 'x="300.0"'
    end
  end

  describe '#weather_temperature_chart' do
    it 'draws the high and the low' do
      chart = helper.weather_temperature_chart([build(:weather_reading)], from: Date.new(2026, 10, 1), days: 10)
      expect(chart.scan('<polyline').size).to eq 2
    end
  end

  describe '#weather_axis_days' do
    let(:planted_at) { Date.new(2026, 10, 1) }

    it 'spans the crop lifespan, and its last day' do
      expect(helper.weather_axis_days(instance_double(Planting, weather_due_on: planted_at + 100, planted_at:, finished_at: nil))).to eq 101
    end

    it 'runs on to today for a planting still growing past its due date' do
      planting = instance_double(Planting, weather_due_on: Time.zone.today - 20, planted_at: Time.zone.today - 30, finished_at: nil)
      expect(helper.weather_axis_days(planting)).to eq 31
    end

    it 'runs from planting to finishing without a known lifespan' do
      planting = instance_double(Planting, weather_due_on: nil, planted_at:, finished_at: planted_at + 2)
      expect(helper.weather_axis_days(planting)).to eq 3
    end
  end

  describe '#weather_seasons' do
    it 'splits the axis into the seasons it passes through, southern hemisphere' do
      seasons = helper.weather_seasons(-41.3, from: Date.new(2026, 8, 25), days: 20)
      expect(seasons).to eq [{ season: :winter, first: 0, last: 6 }, { season: :spring, first: 7, last: 19 }]
    end

    it 'uses the northern seasons north of the equator' do
      expect(helper.weather_seasons(51.5, from: Date.new(2026, 8, 25), days: 3).pluck(:season)).to eq [:summer]
    end

    it 'is empty when we do not know where the garden is' do
      expect(helper.weather_seasons(nil, from: Date.new(2026, 8, 25), days: 3)).to be_empty
    end
  end

  describe 'expected weather' do
    let(:from) { Date.new(2026, 10, 1) }
    let(:observed) { [build(:weather_reading, date: from, rainfall_mm: 2.0)] }
    let(:expected) { [build(:weather_reading, date: from + 1, rainfall_mm: 4.0)] }

    it 'draws expected rain as paler bars' do
      expect(helper.weather_rain_chart(observed, from:, days: 10, expected:).scan('class="weather-expected"').size).to eq 1
    end

    it 'draws expected temperature as paler lines, high and low' do
      expect(helper.weather_temperature_chart(observed, from:, days: 10, expected:).scan('weather-expected').size).to eq 2
    end

    it 'draws no expected lines when there is nothing expected' do
      expect(helper.weather_temperature_chart(observed, from:, days: 10)).not_to include 'weather-expected'
    end
  end
end
