# frozen_string_literal: true

require 'rails_helper'

describe ApplyCropJobTemplate do
  subject(:apply) { described_class.new(template, planting, today:) }

  let(:today) { Date.new(2026, 10, 23) }
  let(:planting) { create(:planting, planted_at: Date.new(2026, 10, 20)) }
  let(:template) { create(:crop_job_template, crop: planting.crop) }
  let!(:stake) { create(:crop_job_step, crop_job_template: template, name: 'Stake', offset_amount: 2, offset_unit: 'weeks') }

  describe '#call' do
    it 'makes a job for a step' do
      expect(apply.call.map(&:name)).to eq ['Stake']
    end

    it 'dates the job from the planting' do
      expect(apply.call.first.due_date).to eq Date.new(2026, 11, 3)
    end

    it 'makes the job the planting owner\'s' do
      expect(apply.call.first.owner).to eq planting.owner
    end

    it 'makes the job about the planting' do
      expect(apply.call.first.jobbable).to eq planting
    end

    it 'puts the job in the planting\'s garden' do
      expect(apply.call.first.garden).to eq planting.garden
    end

    it 'records the step the job came from' do
      expect(apply.call.first.crop_job_step).to eq stake
    end

    context 'when applied a second time' do
      before { described_class.new(template, planting, today:).call }

      it 'makes no more jobs' do
        expect(apply.call).to be_empty
      end
    end

    context 'with a step that fell before today' do
      before { create(:crop_job_step, crop_job_template: template, name: 'Harden off', offset_amount: 1, offset_unit: 'days') }

      it 'leaves it out' do
        expect(apply.call.map(&:name)).not_to include 'Harden off'
      end
    end

    context 'with a step on the first harvest and no harvest date known' do
      before { create(:crop_job_step, crop_job_template: template, name: 'Pick', anchor: 'first_harvest') }

      it 'leaves it out' do
        expect(apply.call.map(&:name)).not_to include 'Pick'
      end
    end

    context 'with a planting that has no planting date' do
      let(:planting) { create(:planting, planted_at: nil) }

      it 'makes no jobs' do
        expect(apply.call).to be_empty
      end
    end
  end
end
