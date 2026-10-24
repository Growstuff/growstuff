# frozen_string_literal: true

require 'rails_helper'

describe CropJobSchedule do
  subject(:entries) { described_class.new(template, planting_out_on:, today:).entries }

  let(:crop) { create(:crop, median_days_to_first_harvest: 90) }
  let(:template) { create(:crop_job_template, crop:) }
  let(:today) { Date.new(2026, 9, 1) }
  let(:planting_out_on) { Date.new(2026, 9, 8) }

  def add_step(**attributes)
    create(:crop_job_step, crop_job_template: template, **attributes)
  end

  context 'with a step after planting out' do
    before { add_step(offset_amount: 3, offset_unit: 'weeks', direction: 'after', anchor: 'planting_out') }

    it 'is that long after the planting out day' do
      expect(entries.first.date).to eq Date.new(2026, 9, 29)
    end

    it 'is not past' do
      expect(entries.first).not_to be_past
    end
  end

  context 'with a step before planting out' do
    before { add_step(offset_amount: 2, offset_unit: 'weeks', direction: 'before', anchor: 'planting_out') }

    it 'is before the planting out day' do
      expect(entries.first.date).to eq Date.new(2026, 8, 25)
    end

    it 'is past when it is already gone' do
      expect(entries.first).to be_past
    end
  end

  context 'with a step in months' do
    before { add_step(offset_amount: 1, offset_unit: 'months', direction: 'after', anchor: 'planting_out') }

    it 'counts calendar months' do
      expect(entries.first.date).to eq Date.new(2026, 10, 8)
    end
  end

  context 'with a step after first harvest' do
    before { add_step(offset_amount: 0, offset_unit: 'days', direction: 'after', anchor: 'first_harvest') }

    it 'is when the crop is first harvested, from its median days' do
      expect(entries.first.date).to eq Date.new(2026, 12, 7)
    end

    context 'when the crop has no median days' do
      let(:crop) { create(:crop, median_days_to_first_harvest: nil) }

      it 'has no date' do
        expect(entries.first.date).to be_nil
      end
    end
  end

  context 'with no steps' do
    it { is_expected.to be_empty }
  end
end
