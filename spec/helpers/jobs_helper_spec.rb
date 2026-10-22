# frozen_string_literal: true

require 'rails_helper'

describe JobsHelper do
  let(:today) { Date.new(2026, 10, 21) }

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
end
