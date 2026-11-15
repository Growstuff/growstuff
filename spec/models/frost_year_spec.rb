# frozen_string_literal: true

require 'rails_helper'

describe FrostYear do
  subject(:frost_year) { create(:frost_year) }

  it { is_expected.to be_valid }

  it 'allows one row per cell, threshold and year' do
    expect(build(:frost_year, year: frost_year.year)).not_to be_valid
  end

  describe '.with_frost' do
    before { create(:frost_year, first_frost: nil, last_frost: nil) }

    it 'leaves out years without frost' do
      expect(described_class.with_frost).to be_empty
    end
  end
end
