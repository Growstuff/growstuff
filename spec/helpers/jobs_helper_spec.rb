# frozen_string_literal: true

require 'rails_helper'

describe JobsHelper do
  let(:today) { Date.new(2026, 10, 21) }

  describe '#job_due_label' do
    def label(due_date)
      helper.job_due_label(build(:job, due_date:), today)
    end

    it 'gives no label without a day' do
      expect(label(nil)).to be_nil
    end

    it 'names the weekday for a job in the next few days' do
      expect(label(Date.new(2026, 10, 24))).to eq 'Sat'
    end

    it 'names the weekday for a job from the past week' do
      expect(label(Date.new(2026, 10, 20))).to eq 'last Tuesday'
    end

    it 'gives the date for a job from longer ago' do
      expect(label(Date.new(2026, 10, 10))).to eq 'Sat 10 Oct'
    end

    it 'gives the date for a job further off' do
      expect(label(Date.new(2026, 11, 3))).to eq 'Tue 3 Nov'
    end
  end

  describe '#job_celebrations' do
    subject(:words) { helper.job_celebrations }

    it 'has a message for each size of streak' do
      expect(words[:levels].keys).to eq %w(one two three many)
    end

    it 'leaves the job\'s name for the script to fill in' do
      expect(words[:crossed_off]).to include('{name}')
    end

    it 'leaves the count for the script to fill in' do
      expect(words[:done][:other]).to include('{count}')
    end
  end

  describe '#job_date_label' do
    def date_label(**attributes)
      helper.job_date_label(build(:job, **attributes), today)
    end

    it 'is the day it is due, for a job not crossed off' do
      expect(date_label(due_date: Date.new(2026, 10, 24))).to eq 'Sat'
    end

    it 'is when it was crossed off, not when it was due, once it is' do
      crossed_off = date_label(due_date: Date.new(2026, 10, 24), finished: true, finished_at: Time.zone.local(2026, 10, 20, 9))
      expect(crossed_off).to eq 'done last Tuesday'
    end

    it 'says today for a job crossed off today' do
      expect(date_label(finished: true, finished_at: Time.zone.local(2026, 10, 21, 9))).to eq 'done today'
    end

    it 'gives the date for a job crossed off longer ago' do
      expect(date_label(finished: true, finished_at: Time.zone.local(2026, 10, 10, 9))).to eq 'done Sat 10 Oct'
    end

    it 'is the day it was due, for a job crossed off before that was recorded' do
      expect(date_label(due_date: Date.new(2026, 10, 20), finished: true, finished_at: nil)).to eq 'last Tuesday'
    end

    it 'is nothing for a job with no day' do
      expect(date_label(due_date: nil)).to be_nil
    end
  end
end
