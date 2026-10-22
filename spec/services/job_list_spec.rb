# frozen_string_literal: true

require 'rails_helper'

describe JobList do
  subject(:list) { described_class.new(jobs, today:) }

  # A Wednesday, so the rest of the week is Thursday to Sunday the 25th.
  let(:today) { Date.new(2026, 10, 21) }
  let(:jobs) { [due_today, saturday, next_week, overdue, no_day] }
  let(:due_today) { build(:job, due_date: today) }
  let(:saturday) { build(:job, due_date: Date.new(2026, 10, 24)) }
  let(:next_week) { build(:job, due_date: Date.new(2026, 10, 28)) }
  let(:overdue) { build(:job, due_date: Date.new(2026, 10, 19)) }
  let(:no_day) { build(:job, due_date: nil) }

  def group(key)
    list.groups.find { |group| group.key == key }
  end

  it 'shows the groups in order' do
    expect(list.groups.map(&:key)).to eq %i(today week soon someday)
  end

  it 'puts jobs due today in Today' do
    expect(group(:today).jobs).to eq [due_today]
  end

  it 'puts jobs for the rest of the week in This week' do
    expect(group(:week).jobs).to eq [saturday]
  end

  it 'puts late and later jobs in Soon' do
    expect(group(:soon).jobs).to contain_exactly(next_week, overdue)
  end

  it 'puts jobs without a day in Some day' do
    expect(group(:someday).jobs).to eq [no_day]
  end

  context 'without any jobs' do
    let(:jobs) { [] }

    it 'still has places to drop one' do
      expect(list.groups.map(&:key)).to eq %i(today week someday)
    end
  end

  describe 'the day a dropped job gets' do
    it 'is today for Today' do
      expect(group(:today).drop_date).to eq today
    end

    it 'is the Sunday for This week' do
      expect(group(:week).drop_date).to eq Date.new(2026, 10, 25)
    end

    it 'is no day for Some day' do
      expect(group(:someday).drop_date).to be_nil
    end

    it 'is nothing for Soon' do
      expect(group(:soon)).not_to be_droppable
    end
  end

  context 'when today is Sunday' do
    let(:today) { Date.new(2026, 10, 25) }
    let(:jobs) { [due_today] }

    it 'has no This week, as none of the week is left' do
      expect(list.groups.map(&:key)).to eq %i(today someday)
    end
  end
end
