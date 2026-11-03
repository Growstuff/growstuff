# frozen_string_literal: true

require 'rails_helper'

describe CropJobTemplatesHelper do
  describe '#crop_job_when' do
    subject { helper.crop_job_when(step) }

    let(:step) { build(:crop_job_step, offset_amount:, offset_unit:, direction:, anchor:) }
    let(:offset_amount) { 2 }
    let(:offset_unit) { 'weeks' }
    let(:direction) { 'after' }
    let(:anchor) { 'planting_out' }

    it { is_expected.to eq '2 weeks after planting out' }

    context 'with one week' do
      let(:offset_amount) { 1 }
      let(:direction) { 'before' }
      let(:anchor) { 'sowing' }

      it { is_expected.to eq '1 week before sowing' }
    end

    context 'with no offset' do
      let(:offset_amount) { 0 }
      let(:anchor) { 'first_harvest' }

      it { is_expected.to eq 'at first harvest' }
    end
  end

  describe '#crop_job_seasons' do
    let(:template) { build(:crop_job_template, name: 'Tomato jobs', season: 'spring_summer') }

    it 'gives the months and the season for a template made for part of the year' do
      expect(helper.crop_job_seasons([template], -41.3))
        .to eq [{ name: 'Tomato jobs', season: 'spring and summer', months: [1, 2, 9, 10, 11, 12] }]
    end

    it { expect(helper.crop_job_seasons([template], nil)).to eq [] }
    it { expect(helper.crop_job_seasons([build(:crop_job_template, season: 'any')], -41.3)).to eq [] }
  end
end
