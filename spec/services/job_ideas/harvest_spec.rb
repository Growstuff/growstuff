# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::Harvest do
  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }
  let(:crop) { create(:crop, perennial: false) }
  let(:days_to_first_harvest) { 60 }
  let(:planted_at) { Date.new(2026, 8, 1) }
  let!(:planting) { create(:planting, owner: member, crop:, planted_at:) }

  # Saving a planting works out the crop's medians from the plantings.
  before { crop.update!(median_days_to_first_harvest: days_to_first_harvest) }

  it 'has an idea for a planting expected to be ready' do
    expect(ideas.map(&:planting)).to eq [planting]
  end

  it 'says when it was expected' do
    expect(ideas.first.on).to eq Date.new(2026, 9, 30)
  end

  it 'says it is a prediction' do
    expect(ideas.first.period).to eq :predicted
  end

  it 'is about the crop' do
    expect(ideas.first.crop).to eq crop
  end

  it 'keys the idea by planting' do
    expect(ideas.first.key).to eq "harvest:#{planting.id}"
  end

  context 'when it is not ready yet' do
    let(:planted_at) { Date.new(2026, 10, 1) }

    it { is_expected.to be_empty }
  end

  context 'when the crop has no expected time to harvest' do
    let(:days_to_first_harvest) { nil }

    it { is_expected.to be_empty }
  end

  context 'with a perennial crop' do
    let(:crop) { create(:crop, perennial: true) }

    it { is_expected.to be_empty }
  end

  context 'with a finished planting' do
    let!(:planting) { create(:planting, owner: member, crop:, planted_at:, finished: true) }

    it { is_expected.to be_empty }
  end

  context 'with someone else\'s planting' do
    let!(:planting) { create(:planting, crop:, planted_at:) }

    it { is_expected.to be_empty }
  end

  context 'when it was harvested from two weeks ago' do
    before { create(:harvest, planting:, harvested_at: Date.new(2026, 10, 9)) }

    it 'has an idea for it' do
      expect(ideas.map(&:planting)).to eq [planting]
    end

    it 'says when it was last harvested' do
      expect(ideas.first.on).to eq Date.new(2026, 10, 9)
    end

    it 'says it was harvested' do
      expect(ideas.first.period).to eq :harvested
    end
  end

  context 'when it was harvested from this week' do
    before { create(:harvest, planting:, harvested_at: Date.new(2026, 10, 20)) }

    it { is_expected.to be_empty }
  end

  context 'when it has been harvested from, but nothing says when it would be ready' do
    let(:days_to_first_harvest) { nil }
    let(:planted_at) { Date.new(2026, 10, 1) }

    before { create(:harvest, planting:, harvested_at: Date.new(2026, 10, 9)) }

    it 'has an idea for it' do
      expect(ideas.map(&:planting)).to eq [planting]
    end
  end

  context 'when the member already has a job to harvest it' do
    before { create(:job, owner: member, name: 'Harvest', action: 'harvest', jobbable: planting) }

    it { is_expected.to be_empty }
  end
end
