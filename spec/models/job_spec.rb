# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Job do
  describe 'active scope' do
    it 'returns jobs that are not finished' do
      active_job = create(:job, finished: false)
      finished_job = create(:job, finished: true)

      expect(described_class.active).to include(active_job)
      expect(described_class.active).not_to include(finished_job)
    end

    it 'treats nil finished as active' do
      job = create(:job, finished: nil)
      expect(described_class.active).to include(job)
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
  end

  describe '#planting_id=' do
    let(:planting) { create(:planting) }

    it 'makes the job about that planting' do
      job = build(:job, planting_id: planting.id)
      expect(job.jobbable).to eq planting
    end

    it 'leaves a job about a crop alone when the form chooses no planting' do
      crop = create(:crop)
      job = build(:job, jobbable: crop)
      job.planting_id = ''
      expect(job.jobbable).to eq crop
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
    let!(:this_week) { create(:job, finished: true) }

    before do
      create(:job, finished: false)
      create(:job, finished: true).update_column(:finished_at, 2.weeks.ago) # rubocop:disable Rails/SkipsModelValidations
    end

    it 'has the jobs crossed off since the week began' do
      expect(described_class.finished_this_week).to eq [this_week]
    end
  end
end
