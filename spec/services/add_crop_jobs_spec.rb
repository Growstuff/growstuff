# frozen_string_literal: true

require 'rails_helper'

describe AddCropJobs do
  subject(:jobs) { described_class.new(member, crop, today:).call }

  let(:member) { create(:member) }
  let(:crop) { create(:tomato) }
  let(:today) { Date.new(2026, 11, 1) }
  let(:template) { create(:crop_job_template, crop:, status: 'published') }

  before do
    create(:crop_job_step, crop_job_template: template, name: 'Stake the plants', offset_amount: 2)
    create(:crop_job_step, crop_job_template: template, name: 'Feed the plants', offset_amount: 4)
  end

  context 'without a planting' do
    it { expect(jobs.map(&:name)).to eq ['Stake the plants', 'Feed the plants'] }
    it { expect(jobs.map(&:due_date)).to all(be_nil) }
    it { expect(jobs.map(&:jobbable)).to all(eq crop) }
    it { expect(jobs.map(&:owner)).to all(eq member) }

    context 'when added before' do
      before { described_class.new(member, crop, today:).call }

      it { expect(jobs).to be_empty }
    end
  end

  context 'with a planting' do
    before { create(:planting, crop:, owner: member, planted_at: today) }

    it { expect(jobs.map(&:due_date)).to eq [today + 2.weeks, today + 4.weeks] }
    it { expect(jobs.map(&:jobbable)).to all(be_a(Planting)) }

    context 'when added before' do
      before { described_class.new(member, crop, today:).call }

      it { expect(jobs).to be_empty }
    end
  end

  context 'with a planting of a variety' do
    let(:variety) { create(:crop, name: 'cherry tomato', parent: crop) }

    before { create(:planting, crop: variety, owner: member, planted_at: today) }

    it { expect(jobs.size).to eq 2 }
  end

  context 'with only another member\'s planting' do
    before { create(:planting, crop:, planted_at: today) }

    it { expect(jobs.map(&:jobbable)).to all(eq crop) }
  end

  context 'with a draft template' do
    let(:template) { create(:crop_job_template, crop:, status: 'draft') }

    it { expect(jobs).to be_empty }
  end
end
