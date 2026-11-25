# frozen_string_literal: true

require 'rails_helper'

describe DateTextHelper do
  let(:today) { Date.new(2026, 11, 17) }

  describe '#date_text' do
    it 'leaves the year out for a recent date' do
      expect(helper.date_text(Date.new(2026, 3, 4), '%-d %b', '%-d %b %Y', today:)).to eq '4 Mar'
    end

    it 'leaves the year out for a date a year ago exactly' do
      expect(helper.date_text(Date.new(2025, 11, 17), '%-d %b', '%-d %b %Y', today:)).to eq '17 Nov'
    end

    it 'adds the year for a date more than a year ago' do
      expect(helper.date_text(Date.new(2025, 11, 16), '%-d %b', '%-d %b %Y', today:)).to eq '16 Nov 2025'
    end
  end

  describe '#month_day_text' do
    it 'adds the year to a date from long ago' do
      expect(helper.month_day_text(Date.new(2000, 1, 4))).to eq 'Jan 04, 2000'
    end
  end
end
