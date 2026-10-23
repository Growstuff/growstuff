# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::PastJobs do
  include ActiveSupport::Testing::TimeHelpers

  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }
  let(:done_on) { Date.new(2025, 10, 28) }
  let(:crop) { create(:crop) }
  let!(:job) { create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: done_on, jobbable: crop) }

  it 'has an idea for a job finished then' do
    expect(ideas.map(&:name)).to eq ['Snip off scapes']
  end

  it 'says when it was done' do
    expect(ideas.first.on).to eq done_on
  end

  it 'is about the crop the job was about' do
    expect(ideas.first.crop).to eq crop
  end

  it 'dates a job by when it was crossed off, if known' do
    job.update!(due_date: nil)
    job.update!(finished: false)
    travel_to(Time.zone.local(2025, 10, 25, 12)) { job.update!(finished: true) }
    expect(ideas.first.on).to eq Date.new(2025, 10, 25)
  end

  it 'counts the years it was done' do
    expect(ideas.first.years).to eq 1
  end

  context 'with a job done two years ago' do
    let(:done_on) { Date.new(2024, 10, 30) }

    it 'has an idea for it' do
      expect(ideas.map(&:name)).to eq ['Snip off scapes']
    end
  end

  context 'with a job done more than five years ago' do
    let(:done_on) { Date.new(2020, 10, 28) }

    it { is_expected.to be_empty }
  end

  context 'with a job done two weeks before this day' do
    let(:done_on) { Date.new(2025, 10, 9) }

    it 'has an idea for it' do
      expect(ideas.map(&:name)).to eq ['Snip off scapes']
    end
  end

  context 'with a job done more than three weeks after this day' do
    let(:done_on) { Date.new(2025, 11, 20) }

    it { is_expected.to be_empty }
  end

  context 'with a job done a month earlier' do
    let(:done_on) { Date.new(2025, 9, 20) }

    it { is_expected.to be_empty }
  end

  context 'with a job that was not finished' do
    before { job.update!(finished: false) }

    it { is_expected.to be_empty }
  end

  context 'with someone else\'s job' do
    let!(:job) { create(:job, :finished_without_time, name: 'Snip off scapes', due_date: done_on) }

    it { is_expected.to be_empty }
  end

  context 'when the member already has the job open' do
    before { create(:job, owner: member, name: 'snip off scapes', due_date: today) }

    it { is_expected.to be_empty }
  end

  context 'with a job made from a template step' do
    before { job.update!(crop_job_step: create(:crop_job_step)) }

    it { is_expected.to be_empty }
  end

  context 'with the same job done twice in one year' do
    before { create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: done_on + 3.days, jobbable: crop) }

    it 'has one idea' do
      expect(ideas.size).to eq 1
    end

    it 'counts the year once' do
      expect(ideas.first.years).to eq 1
    end
  end

  context 'with the same job done in an earlier year too' do
    before do
      create(:job, :finished_without_time, owner: member, name: 'Snip off scapes', due_date: Date.new(2024, 10, 26), jobbable: crop)
    end

    it 'has one idea' do
      expect(ideas.size).to eq 1
    end

    it 'dates it the latest time' do
      expect(ideas.first.on).to eq done_on
    end

    it 'counts the years' do
      expect(ideas.first.years).to eq 2
    end
  end
end
