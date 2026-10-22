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

  it 'says when a job is late' do
    expect(label(Date.new(2026, 10, 20))).to eq 'was Tue'
  end

  it 'gives the date for a job further off' do
    expect(label(Date.new(2026, 11, 3))).to eq 'Tue 3 Nov'
  end
end
