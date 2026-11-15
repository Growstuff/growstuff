# frozen_string_literal: true

require 'rails_helper'

describe GrowingDegreeDays do
  subject(:degree_days) { described_class.new(base: 10) }

  let(:warm_day) { build(:weather_reading, temp_max_c: 22.0, temp_min_c: 12.0) }

  describe '#total' do
    it 'adds up each day' do
      cold_day = build(:weather_reading, temp_max_c: 11.0, temp_min_c: 3.0)
      expect(degree_days.total([warm_day, cold_day, warm_day])).to eq 14
    end
  end

  describe '#for_day' do
    it 'is how far the average temperature is above the base' do
      expect(degree_days.for_day(warm_day)).to eq 7
    end

    context 'when the day is colder than the base' do
      let(:cold_day) { build(:weather_reading, temp_max_c: 11.0, temp_min_c: 3.0) }

      it 'is nothing' do
        expect(degree_days.for_day(cold_day)).to eq 0
      end
    end

    context 'without temperatures' do
      let(:unknown_day) { build(:weather_reading, temp_max_c: nil, temp_min_c: nil) }

      it 'is nothing' do
        expect(degree_days.for_day(unknown_day)).to eq 0
      end
    end
  end

  describe '#date_reaching' do
    let(:readings) do
      (Date.new(2026, 10, 1)..Date.new(2026, 10, 3)).map { |date| build(:weather_reading, date:, temp_max_c: 22.0, temp_min_c: 12.0) }
    end

    it 'is the day the total passes the target' do
      expect(degree_days.date_reaching(10, readings)).to eq Date.new(2026, 10, 2)
    end

    it 'is the day the total just equals the target' do
      expect(degree_days.date_reaching(14, readings)).to eq Date.new(2026, 10, 2)
    end

    it 'is nil when the readings never add up to the target' do
      expect(degree_days.date_reaching(100, readings)).to be_nil
    end

    it 'is nil without readings' do
      expect(degree_days.date_reaching(10, [])).to be_nil
    end
  end
end
