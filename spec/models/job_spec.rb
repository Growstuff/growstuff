# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Job do
  include ActiveSupport::Testing::TimeHelpers

  describe '.active' do
    subject(:active) { described_class.active }

    it 'has jobs that are not finished' do
      expect(active).to include(create(:job, finished: false))
    end

    it 'has jobs that were never crossed off or put back' do
      expect(active).to include(create(:job, finished: nil))
    end

    it 'leaves out jobs that are finished' do
      expect(active).not_to include(create(:job, finished: true))
    end
  end

  describe '#crop_job_step' do
    subject(:job) { create(:job, crop_job_step: step) }

    let(:step) { create(:crop_job_step) }

    it 'is the template step the job was made from' do
      expect(job.reload.crop_job_step).to eq step
    end

    it 'is optional' do
      expect(build(:job, crop_job_step: nil)).to be_valid
    end

    context 'when the step is deleted' do
      before do
        job
        step.destroy
      end

      it 'leaves the job' do
        expect(job.reload.crop_job_step).to be_nil
      end
    end
  end

  describe '#action' do
    subject(:job) { build(:job, owner:, action:, jobbable:) }

    let(:owner) { create(:member) }
    let(:action) { 'plant' }
    let(:jobbable) { create(:crop) }

    it { is_expected.to be_valid }

    it 'is optional' do
      expect(build(:job, action: nil)).to be_valid
    end

    context 'with an action that does not exist' do
      let(:action) { 'bury' }

      it { is_expected.not_to be_valid }
    end

    context 'when planting seeds' do
      let(:jobbable) { create(:seed, owner:) }

      it { is_expected.to be_valid }
    end

    context 'when planting a planting' do
      let(:jobbable) { create(:planting, owner:) }

      it { is_expected.not_to be_valid }
    end

    context 'when planting with nothing to plant' do
      let(:jobbable) { nil }

      it { is_expected.not_to be_valid }
    end

    context 'when harvesting a crop' do
      let(:action) { 'harvest' }

      it { is_expected.to be_valid }
    end

    context 'when harvesting a planting' do
      let(:action) { 'harvest' }
      let(:jobbable) { create(:planting, owner:) }

      it { is_expected.to be_valid }
    end

    context 'when harvesting seeds' do
      let(:action) { 'harvest' }
      let(:jobbable) { create(:seed, owner:) }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#jobbable' do
    subject(:job) { build(:job, owner:, jobbable:) }

    let(:owner) { create(:member) }

    context 'with one of the owner\'s plantings' do
      let(:jobbable) { create(:planting, owner:) }

      it { is_expected.to be_valid }

      it 'is about that planting' do
        expect(job.planting).to eq jobbable
      end
    end

    context 'with some of the owner\'s seeds' do
      let(:jobbable) { create(:seed, owner:) }

      it { is_expected.to be_valid }
    end

    context 'with a crop' do
      let(:jobbable) { create(:crop) }

      it { is_expected.to be_valid }

      it 'is not about a planting' do
        expect(job.planting).to be_nil
      end
    end

    context 'with another member\'s planting' do
      let(:jobbable) { create(:planting) }

      it { is_expected.not_to be_valid }
    end

    context 'with something that cannot have jobs' do
      let(:jobbable) { create(:garden, owner:) }

      it { is_expected.not_to be_valid }
    end

    context 'with a planting that is not there' do
      let(:jobbable) { nil }

      before { job.assign_attributes(jobbable_type: 'Planting', jobbable_id: 0) }

      it { is_expected.not_to be_valid }

      it 'says the job needs something to be about' do
        job.validate
        expect(job.errors[:jobbable]).to eq ['must exist']
      end
    end

    context 'with a type and no id' do
      let(:jobbable) { nil }

      before { job.assign_attributes(jobbable_type: 'Crop', jobbable_id: nil) }

      it { is_expected.not_to be_valid }
    end
  end

  describe '#planting_id=' do
    subject(:job) { build(:job, jobbable:) }

    let(:jobbable) { create(:crop) }
    let(:planting) { create(:planting) }

    context 'with a planting\'s id' do
      before { job.planting_id = planting.id }

      it 'makes the job about that planting' do
        expect(job.jobbable).to eq planting
      end
    end

    context 'with no id, as when the form chooses no planting' do
      before { job.planting_id = '' }

      it 'leaves a job about a crop alone' do
        expect(job.jobbable).to eq jobbable
      end
    end
  end

  describe '#finished_at' do
    let(:job) { create(:job, finished: false) }

    it 'is set when the job is crossed off' do
      job.update!(finished: true)
      expect(job.finished_at).to be_within(1.minute).of(Time.zone.now)
    end

    it 'is cleared when the job is put back' do
      job.update!(finished: true)
      job.update!(finished: false)
      expect(job.finished_at).to be_nil
    end

    it 'is left alone when something else changes' do
      job.update!(finished: true)
      expect { job.update!(name: 'Another name') }.not_to(change { job.reload.finished_at })
    end
  end

  describe '.finished_this_week' do
    subject(:finished) { described_class.finished_this_week }

    it 'has the jobs crossed off since the week began' do
      expect(finished).to include(create(:job, finished: true))
    end

    it 'leaves out jobs crossed off earlier' do
      earlier = travel_to(2.weeks.ago) { create(:job, finished: true) }
      expect(finished).not_to include(earlier)
    end

    it 'leaves out jobs not crossed off' do
      expect(finished).not_to include(create(:job, finished: false))
    end
  end
end
