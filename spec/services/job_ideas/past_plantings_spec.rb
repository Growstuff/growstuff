# frozen_string_literal: true

require 'rails_helper'

describe JobIdeas::PastPlantings do
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

  it 'is about the planting it was last done' do
    expect(ideas.first.planting).to eq planting
  end

  it 'keys the idea by crop' do
    expect(ideas.first.key).to eq "past_planting:#{crop.id}"
  end

  it 'counts the years it was planted' do
    expect(ideas.first.years).to eq 1
  end

  context 'with a planting two years ago' do
    let(:planted_at) { Date.new(2024, 10, 30) }

    it 'has an idea for it' do
      expect(ideas.map(&:crop)).to eq [crop]
    end
  end

  context 'with a planting more than five years ago' do
    let(:planted_at) { Date.new(2020, 10, 28) }

    it { is_expected.to be_empty }
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

  context 'when the crop was planted in an earlier year too' do
    before { create(:planting, owner: member, crop:, planted_at: Date.new(2024, 10, 26)) }

    it 'has one idea' do
      expect(ideas.size).to eq 1
    end

    it 'dates it the latest time' do
      expect(ideas.first.on).to eq planted_at
    end

    it 'counts the years' do
      expect(ideas.first.years).to eq 2
    end
  end
end
