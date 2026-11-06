# frozen_string_literal: true

require 'rails_helper'

describe AddCropJobs do
  subject(:service) { described_class.new(member, crop, today:) }

  let(:member) { create(:member) }
  let(:crop) { create(:tomato) }
  let(:today) { Date.new(2026, 11, 1) }
  let(:saturday) { Date.new(2026, 11, 7) }
  let(:template) { create(:crop_job_template, crop:, status: 'published') }

  before do
    create(:crop_job_step, crop_job_template: template, name: 'Stake the plants', offset_amount: 2)
    create(:crop_job_step, crop_job_template: template, name: 'Feed the plants', offset_amount: 4)
  end

  describe '#call for a planting to come' do
    subject(:jobs) { service.call }

    it { expect(jobs.map(&:name)).to eq ['Stake the plants', 'Feed the plants'] }
    it { expect(jobs.map(&:jobbable)).to all(eq crop) }
    it { expect(jobs.map(&:owner)).to all(eq member) }
    it { expect(jobs.map(&:crop_job_step)).to eq template.steps.to_a }

    it 'counts from the next Saturday unless told a day' do
      expect(jobs.map(&:due_date)).to eq [saturday + 2.weeks, saturday + 4.weeks]
    end

    context 'with a day to plant on' do
      subject(:jobs) { described_class.new(member, crop, planting_on: Date.new(2026, 12, 1), today:).call }

      it { expect(jobs.map(&:due_date)).to eq [Date.new(2026, 12, 15), Date.new(2026, 12, 29)] }
    end

    context 'with a step before planting' do
      subject(:due) do
        described_class.new(member, crop, planting_on: Date.new(2026, 12, 1), today:).call.to_h { |job| [job.name, job.due_date] }
      end

      before { create(:crop_job_step, crop_job_template: template, name: 'Dig in compost', offset_amount: 1, direction: 'before') }

      it { expect(due['Dig in compost']).to eq Date.new(2026, 11, 24) }
    end

    context 'with a step that would already be past' do
      subject(:due) { service.call.to_h { |job| [job.name, job.due_date] } }

      before { create(:crop_job_step, crop_job_template: template, name: 'Dig in compost', offset_amount: 2, direction: 'before') }

      it { expect(due['Dig in compost']).to eq today }
    end

    context 'with a step that has no day of its own' do
      subject(:due) { service.call.to_h { |job| [job.name, job.due_date] } }

      before { create(:crop_job_step, crop_job_template: template, name: 'Pick the fruit', anchor: 'first_harvest') }

      it { expect(due['Pick the fruit']).to be_nil }
    end

    context 'when added before' do
      before { described_class.new(member, crop, today:).call }

      it { expect(jobs).to be_empty }
    end

    context 'with a draft template' do
      let(:template) { create(:crop_job_template, crop:, status: 'draft') }

      it { expect(jobs).to be_empty }
    end
  end

  describe '#call for a planting' do
    subject(:jobs) { described_class.new(member, crop, planting:, today:).call }

    let(:planting) { create(:planting, crop:, owner: member, planted_at: today - 1.week) }

    it { expect(jobs.map(&:jobbable)).to all(eq planting) }
    it { expect(jobs.map(&:crop_job_step)).to eq template.steps.to_a }
    it { expect(jobs.map(&:due_date)).to eq [today + 1.week, today + 3.weeks] }

    context 'when added before' do
      before { described_class.new(member, crop, planting:, today:).call }

      it { expect(jobs).to be_empty }
    end
  end

  describe '#plantings' do
    subject { service.plantings }

    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }
    let!(:own) { create(:planting, crop:, owner: member, planted_at: today - 1.week) }
    let!(:of_variety) { create(:planting, crop: variety, owner: member, planted_at: today) }

    before do
      create(:planting, crop:, planted_at: today)
      create(:planting, crop: create(:crop, name: 'carrot'), owner: member, planted_at: today)
      create(:planting, crop:, owner: member, planted_at: nil)
    end

    it { is_expected.to eq [of_variety, own] }
  end

  describe '#open_plantings' do
    subject { service.open_plantings }

    let!(:done) { create(:planting, crop:, owner: member, planted_at: today) }
    let!(:waiting) { create(:planting, crop:, owner: member, planted_at: today - 1.day) }

    before { described_class.new(member, crop, planting: done, today:).call }

    it { is_expected.to eq [waiting] }
  end

  describe '#pending?' do
    it { is_expected.to be_pending }

    context 'when the jobs have been added for a planting to come' do
      before { service.call }

      it { is_expected.not_to be_pending }
    end

    context 'when the jobs have been added for a planting and for one to come' do
      let(:planting) { create(:planting, crop:, owner: member, planted_at: today) }

      before do
        described_class.new(member, crop, planting:, today:).call
        service.call
      end

      it { is_expected.not_to be_pending }
    end

    context 'when the jobs have been added for a planting but not for one to come' do
      let(:planting) { create(:planting, crop:, owner: member, planted_at: today) }

      before { described_class.new(member, crop, planting:, today:).call }

      it { is_expected.to be_pending }
    end

    context 'when the crop has no templates' do
      subject(:service) { described_class.new(member, create(:crop, name: 'carrot'), today:) }

      it { is_expected.not_to be_pending }
    end
  end

  describe '#to_come?' do
    it { is_expected.to be_to_come }

    context 'when the jobs have been added for a planting to come' do
      before { service.call }

      it { is_expected.not_to be_to_come }
    end
  end

  describe '.default_planting_on' do
    it { expect(described_class.default_planting_on(Date.new(2026, 11, 2))).to eq Date.new(2026, 11, 7) }
    it { expect(described_class.default_planting_on(Date.new(2026, 11, 6))).to eq Date.new(2026, 11, 7) }
    it { expect(described_class.default_planting_on(Date.new(2026, 11, 7))).to eq Date.new(2026, 11, 7) }
    it { expect(described_class.default_planting_on(Date.new(2026, 11, 8))).to eq Date.new(2026, 11, 14) }
  end
end
