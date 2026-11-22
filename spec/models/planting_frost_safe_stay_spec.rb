# frozen_string_literal: true

require 'rails_helper'

describe Planting, '#frost_safe_stay' do
  subject(:stay) { planting.frost_safe_stay }

  let(:owner) { create(:member) }
  let(:first_garden) { create(:garden, owner:, frost_safe:) }
  let(:garden) { create(:garden, owner:) }
  let(:frost_safe) { true }
  let(:planting) { create(:planting, garden: first_garden, owner:, planted_at: Date.new(2026, 8, 10)) }

  context 'when it went from a garden that is safe from frost into another' do
    before { planting.transplant_to(garden, on: Date.new(2026, 9, 5)) }

    it 'says when it left' do
      expect(stay.ended_on).to eq Date.new(2026, 9, 5)
    end

    it 'says where it was' do
      expect(stay.garden).to eq first_garden
    end
  end

  context 'when the first garden is not safe from frost' do
    let(:frost_safe) { false }

    before { planting.transplant_to(garden, on: Date.new(2026, 9, 5)) }

    it { is_expected.to be_nil }
  end

  context 'when it has never moved' do
    it { is_expected.to be_nil }
  end
end
