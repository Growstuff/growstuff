# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::PlantedLastYear do
  subject(:ideas) { described_class.new(member, today).ideas }

  let(:today) { Date.new(2026, 10, 23) }
  let(:member) { create(:member) }
  let(:planted_at) { Date.new(2025, 10, 28) }
  let(:crop) { create(:crop, perennial: false) }
  let!(:planting) { create(:planting, owner: member, crop:, planted_at:) }

  it 'has an idea for a crop planted then' do
    expect(ideas.map(&:crop)).to eq [crop]
  end

  it 'says when it was planted' do
    expect(ideas.first.on).to eq planted_at
  end

  it 'is about last year\'s planting' do
    expect(ideas.first.planting).to eq planting
  end

  it 'keys the idea by crop' do
    expect(ideas.first.key).to eq "planted_last_year:#{crop.id}"
  end

  context 'with a planting a month earlier' do
    let(:planted_at) { Date.new(2025, 9, 20) }

    it { is_expected.to be_empty }
  end

  context 'with a perennial crop' do
    let(:crop) { create(:crop, perennial: true) }

    it { is_expected.to be_empty }
  end

  context 'with a planting that failed' do
    let!(:planting) { create(:planting, owner: member, crop:, planted_at:, failed: true) }

    it { is_expected.to be_empty }
  end

  context 'with someone else\'s planting' do
    let!(:planting) { create(:planting, crop:, planted_at:) }

    it { is_expected.to be_empty }
  end

  context 'when they have planted the crop since' do
    before { create(:planting, owner: member, crop:, planted_at: Date.new(2026, 9, 1)) }

    it { is_expected.to be_empty }
  end

  context 'when the crop was planted twice then' do
    before { create(:planting, owner: member, crop:, planted_at: planted_at + 3.days) }

    it 'has one idea' do
      expect(ideas.size).to eq 1
    end
  end
end
