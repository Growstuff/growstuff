# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Community do
  include ActiveSupport::Testing::TimeHelpers

  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:london_member) }
  let(:crop) { create(:crop) }
  let(:done_on) { Date.new(2026, 10, 20) }
  let(:gardeners) { create_list(:edinburgh_member, 3) }

  before do
    create(:planting, owner: member, crop:)
    gardeners.each do |gardener|
      create(:job, :finished_without_time, owner: gardener, name: 'Mound up potatoes', due_date: done_on, jobbable: crop)
    end
  end

  it 'has an idea for what enough of them did' do
    expect(ideas.map(&:name)).to eq ['Mound up potatoes']
  end

  it 'is about the crop' do
    expect(ideas.first.crop).to eq crop
  end

  it 'counts the gardeners' do
    expect(ideas.first.gardeners).to eq 3
  end

  it 'says it was now' do
    expect(ideas.first.period).to eq :now
  end

  it 'says how many grow the crop' do
    create(:planting, crop:)
    expect(ideas.first.of).to eq 1
  end

  it 'keys the idea by name and crop' do
    expect(ideas.first.key).to eq "community:mound up potatoes:#{crop.id}"
  end

  context 'with gardeners in the other hemisphere' do
    let(:gardeners) { create_list(:south_pole_member, 3) }

    it { is_expected.to be_empty }
  end

  context 'when the member has not said where they are' do
    let(:member) { create(:member) }

    it { is_expected.to be_empty }
  end

  context 'with only two gardeners' do
    let(:gardeners) { create_list(:edinburgh_member, 2) }

    it { is_expected.to be_empty }
  end

  context 'when they did it at this time in earlier years' do
    let(:done_on) { Date.new(2025, 10, 24) }

    it 'says it was earlier' do
      expect(ideas.first.period).to eq :earlier
    end
  end

  context 'with a job at another time of year' do
    let(:done_on) { Date.new(2026, 4, 20) }

    it { is_expected.to be_empty }
  end

  context 'when the member does not grow the crop' do
    before { member.plantings.destroy_all }

    it { is_expected.to be_empty }
  end

  context 'when the job is about another crop' do
    before { Job.update_all(jobbable_id: create(:crop).id) } # rubocop:disable Rails/SkipsModelValidations

    it { is_expected.to be_empty }
  end

  context 'when the jobs are about their plantings of the crop' do
    before do
      Job.destroy_all
      gardeners.each do |gardener|
        create(:job, :finished_without_time, owner: gardener, name: 'Mound up potatoes', due_date: done_on,
                                             jobbable: create(:planting, owner: gardener, crop:))
      end
    end

    it 'counts them' do
      expect(ideas.first.gardeners).to eq 3
    end
  end

  context 'when the member has blocked one of them' do
    before { Block.create!(blocker: member, blocked: gardeners.first) }

    it { is_expected.to be_empty }
  end

  context 'when the member already has the job open' do
    before { create(:job, owner: member, name: 'mound up potatoes', due_date: today) }

    it { is_expected.to be_empty }
  end

  context 'when the jobs were made from a template' do
    before { Job.update_all(crop_job_step_id: create(:crop_job_step).id) } # rubocop:disable Rails/SkipsModelValidations

    it { is_expected.to be_empty }
  end
end
