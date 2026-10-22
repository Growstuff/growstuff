# frozen_string_literal: true

require 'rails_helper'

describe JobList do
  subject(:list) { described_class.new(jobs, today:) }

  # A Wednesday, so this weekend is the 24th and 25th.
  let(:today) { Date.new(2026, 10, 21) }
  let(:jobs) { [saturday, next_week, overdue, no_day] }
  let(:saturday) { build(:job, due_date: Date.new(2026, 10, 24)) }
  let(:next_week) { build(:job, due_date: Date.new(2026, 10, 28)) }
  let(:overdue) { build(:job, due_date: Date.new(2026, 10, 19)) }
  let(:no_day) { build(:job, due_date: nil) }

  def jobs_in(key)
    list.groups.find { |group| group.key == key }.jobs
  end

  it 'shows the groups that have jobs, in order' do
    expect(list.groups.map(&:key)).to eq %i(weekend soon someday)
  end

  it 'puts jobs for the weekend in This weekend' do
    expect(jobs_in(:weekend)).to eq [saturday]
  end

  it 'puts late and later jobs in Soon' do
    expect(jobs_in(:soon)).to contain_exactly(next_week, overdue)
  end

  it 'puts jobs without a day in Some day' do
    expect(jobs_in(:someday)).to eq [no_day]
  end

  context 'without any jobs for the weekend' do
    let(:jobs) { [next_week] }

    it 'leaves the group out' do
      expect(list.groups.map(&:key)).to eq [:soon]
    end
  end

  describe '#weekend_days' do
    it 'is the coming Saturday and Sunday on a weekday' do
      expect(list.weekend_days).to eq [Date.new(2026, 10, 24), Date.new(2026, 10, 25)]
    end

    context 'when today is Sunday' do
      let(:today) { Date.new(2026, 10, 25) }

      it 'is the weekend going on' do
        expect(list.weekend_days).to eq [Date.new(2026, 10, 24), Date.new(2026, 10, 25)]
      end
    end
  end
end
