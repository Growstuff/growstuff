# frozen_string_literal: true

require 'rails_helper'

describe SowingHelper do
  it 'leaves the home page\'s month_name alone: every helper is in every view, so a clash breaks the other' do
    expect(ApplicationController.helpers.month_name(10)).to eq 'October'
  end

  describe '#sow_months_text' do
    {
      [3, 4]             => 'Mar–Apr',
      [7]                => 'Jul',
      [10, 11, 12, 1, 2] => 'Oct–Feb',
      [1, 2, 10, 11, 12] => 'Oct–Feb',
      [12, 1]            => 'Dec–Jan',
      [3, 4, 9, 10]      => 'Mar–Apr, Sep–Oct',
      [2, 4, 6]          => 'Feb, Apr, Jun',
      [9, 3, 4, 10]      => 'Mar–Apr, Sep–Oct'
    }.each do |months, words|
      it("reads #{months.inspect} as #{words}") { expect(helper.sow_months_text(months)).to eq words }
    end

    it('reads all twelve as all year') { expect(helper.sow_months_text((1..12).to_a)).to eq 'All year' }
    it('says nothing of none') { expect(helper.sow_months_text([])).to be_nil }
  end

  describe '#days_range_text' do
    it('is a range') { expect(helper.days_range_text(7, 14)).to eq '7–14' }
    it('is the one number when the ends are the same') { expect(helper.days_range_text(5, 5)).to eq '5' }
    it('is the one number there is, with no minimum') { expect(helper.days_range_text(nil, 10)).to eq '10' }
    it('is the one number there is, with no maximum') { expect(helper.days_range_text(7, nil)).to eq '7' }
    it('says nothing of none') { expect(helper.days_range_text(nil, nil)).to be_nil }
  end

  describe '#season_months' do
    it('has spring in March to May in the northern hemisphere') { expect(helper.season_months(51.5)['Spring']).to eq [3, 4, 5] }
    it('has winter round the year end in the northern hemisphere') { expect(helper.season_months(51.5)['Winter']).to eq [12, 1, 2] }
    it('has spring in September to November in the southern hemisphere') { expect(helper.season_months(-41.3)['Spring']).to eq [9, 10, 11] }
    it('has summer round the year end in the southern hemisphere') { expect(helper.season_months(-41.3)['Summer']).to eq [12, 1, 2] }
    it('covers every month once, in either hemisphere') { expect(helper.season_months(-41.3).values.flatten.sort).to eq (1..12).to_a }

    it('has each season six months on in the southern hemisphere, as it has to be') do
      six_months_on = described_class::NORTHERN_SEASONS.transform_values do |months|
        months.map { |month| ((month + 5) % 12) + 1 }
      end
      expect(described_class::SOUTHERN_SEASONS).to eq(six_months_on)
    end

    it('guesses nothing where the hemisphere is not known') { expect(helper.season_months(nil)).to be_nil }
  end
end
