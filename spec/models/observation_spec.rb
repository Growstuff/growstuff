# frozen_string_literal: true

require 'rails_helper'

describe Observation do
  subject(:observation) { build(:observation) }

  it { is_expected.to be_valid }

  it 'needs a kind from the list' do
    observation.kind = 'aliens'
    expect(observation).not_to be_valid
  end

  it 'can have no kind, which is other' do
    observation.kind = nil
    expect(observation).to be_valid
    expect(observation).not_to be_problem
  end

  it 'needs a time' do
    observation.observed_at = nil
    expect(observation).not_to be_valid
  end

  it 'cannot be in the future' do
    observation.observed_at = 1.day.from_now
    expect(observation).not_to be_valid
  end

  it 'can be in the past' do
    observation.observed_at = 3.weeks.ago
    expect(observation).to be_valid
  end

  describe '#problem?' do
    it { expect(build(:observation, kind: 'disease_observed')).to be_problem }
    it { expect(build(:observation, kind: 'wilting')).to be_problem }
    it { expect(build(:observation, kind: 'flowering')).not_to be_problem }
  end

  describe '.newest_first' do
    it 'puts the latest observed first' do
      planting = create(:planting)
      older = create(:observation, planting: planting, observed_at: 5.days.ago)
      newer = create(:observation, planting: planting, observed_at: 1.day.ago)
      expect(planting.observations.newest_first).to eq [newer, older]
    end
  end

  it 'goes when its planting goes' do
    observation = create(:observation)
    expect { observation.planting.destroy }.to change(described_class, :count).by(-1)
  end
end
