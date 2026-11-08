# frozen_string_literal: true

require 'rails_helper'

describe 'Planting short code' do
  let(:owner) { create(:member) }
  let(:garden) { create(:garden, owner:) }
  let(:crop) { create(:crop) }

  describe 'generation on create' do
    it 'automatically assigns a 4-character short code' do
      planting = create(:planting, owner:, garden:, crop:)
      expect(planting.short_code).to be_present
      expect(planting.short_code.length).to eq(4)
      expect(planting.short_code).to match(/\A[2-9A-HJ-NP-Z]{4}\z/)
    end

    it 'preserves a manually provided valid short code' do
      planting = create(:planting, owner:, garden:, crop:, short_code: 'A2B3')
      expect(planting.short_code).to eq('A2B3')
    end
  end

  describe 'uniqueness' do
    it 'allows the same short code for different owners' do
      other_owner = create(:member)
      other_garden = create(:garden, owner: other_owner)

      create(:planting, owner:, garden:, crop:, short_code: 'WXYZ')
      second_planting = build(:planting, owner: other_owner, garden: other_garden, crop:, short_code: 'WXYZ')

      expect(second_planting).to be_valid
    end

    it 'disallows duplicate short codes for the same owner' do
      create(:planting, owner:, garden:, crop:, short_code: 'WXYZ')
      duplicate = build(:planting, owner:, garden:, crop:, short_code: 'WXYZ')

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:short_code]).to include('has already been taken')
    end
  end

  describe 'format validations' do
    it 'rejects codes not exactly 4 characters' do
      short = build(:planting, owner:, garden:, crop:, short_code: 'ABC')
      expect(short).not_to be_valid

      long = build(:planting, owner:, garden:, crop:, short_code: 'ABCDE')
      expect(long).not_to be_valid
    end

    it 'rejects invalid characters such as ambiguous 0, O, 1, I or lowercase' do
      invalid_chars = %w[0123 ABCD abcd 1XYZ OXYZ]
      invalid_chars.each do |code|
        planting = build(:planting, owner:, garden:, crop:, short_code: code)
        expect(planting).not_to be_valid
      end
    end
  end

  describe '.generate_short_code' do
    it 'returns a 4-character code made of SHORT_CODE_CHARS' do
      code = Planting.generate_short_code
      expect(code.length).to eq(4)
      expect(code).to match(/\A[2-9A-HJ-NP-Z]{4}\z/)
    end

    it 'avoids collision with existing short codes of the owner' do
      allow(Planting::SHORT_CODE_CHARS).to receive(:sample).and_return('A', 'A', 'A', 'A', 'B', 'B', 'B', 'B')
      create(:planting, owner:, garden:, crop:, short_code: 'AAAA')

      generated = Planting.generate_short_code(owner)
      expect(generated).to eq('BBBB')
    end
  end
end
