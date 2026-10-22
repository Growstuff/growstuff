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
    expect(list.groups.map(&:key)).to eq %i(overdue today week soon someday)
  end

  it 'puts jobs due today in Today' do
    expect(group(:today).jobs).to eq [due_today]
  end

  it 'puts jobs for the rest of the week in This week' do
    expect(group(:week).jobs).to eq [saturday]
  end

  it 'puts jobs from before today in Overdue' do
    expect(group(:overdue).jobs).to eq [overdue]
  end

  it 'puts jobs for after this week in Soon' do
    expect(group(:soon).jobs).to eq [next_week]
  end

  it 'puts jobs without a day in Some day' do
    expect(group(:someday).jobs).to eq [no_day]
  end

  it 'cannot drop a job on Overdue' do
    expect(group(:overdue)).not_to be_droppable
  end

  context 'with a crossed off job that was due before today' do
    let(:done) { build(:job, due_date: Date.new(2026, 10, 14), finished: true) }
    let(:done_later) { build(:job, due_date: Date.new(2026, 10, 18), finished: true) }
    let(:jobs) { [due_today, overdue, done, done_later] }

    it 'puts it in Done, at the bottom' do
      expect(list.groups.map(&:key)).to eq %i(overdue today week someday done)
    end

    it 'leaves it out of Overdue' do
      expect(group(:overdue).jobs).to eq [overdue]
    end

    it 'has the latest first' do
      expect(group(:done).jobs).to eq [done_later, done]
    end

    it 'cannot be dropped on' do
      expect(group(:done)).not_to be_droppable
    end
  end

  context 'with a job crossed off in the page being looked at' do
    subject(:list) { described_class.new(jobs, today:, pinned: [just_ticked.id]) }

    let(:just_ticked) { create(:job, due_date: Date.new(2026, 10, 14), finished: true) }
    let(:ticked_before) { create(:job, due_date: Date.new(2026, 10, 15), finished: true) }
    let(:jobs) { [just_ticked, ticked_before] }

    it 'leaves it where its day puts it' do
      expect(group(:overdue).jobs).to eq [just_ticked]
    end

    it 'still moves the others that are crossed off to Done' do
      expect(group(:done).jobs).to eq [ticked_before]
    end
  end

  context 'with crossed off jobs that say when they were crossed off' do
    let(:first) { build(:job, due_date: Date.new(2026, 10, 18), finished: true, finished_at: Time.zone.local(2026, 10, 20)) }
    let(:last) { build(:job, due_date: Date.new(2026, 10, 14), finished: true, finished_at: Time.zone.local(2026, 10, 21)) }
    let(:undated) { build(:job, due_date: nil, finished: true, finished_at: Time.zone.local(2026, 10, 19)) }
    let(:jobs) { [first, undated, last] }

    it 'puts the one crossed off last first, whatever its day' do
      expect(group(:done).jobs).to eq [last, first, undated]
    end
  end

  context 'with a crossed off job that has no day' do
    let(:done_past) { build(:job, due_date: Date.new(2026, 10, 18), finished: true) }
    let(:done_undated) { build(:job, due_date: nil, finished: true) }
    let(:jobs) { [no_day, done_undated, done_past] }

    it 'puts it in Done, not Some day' do
      expect(group(:done).jobs).to include(done_undated)
    end

    it 'leaves a job without a day that is not crossed off in Some day' do
      expect(group(:someday).jobs).to eq [no_day]
    end

    it 'puts it after the ones with a day' do
      expect(group(:done).jobs).to eq [done_past, done_undated]
    end
  end

  context 'with a crossed off job due today' do
    let(:due_today) { build(:job, due_date: today, finished: true) }

    it 'keeps it in Today' do
      expect(group(:today).jobs).to eq [due_today]
    end
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
