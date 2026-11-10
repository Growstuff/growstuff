# frozen_string_literal: true

require 'rails_helper'

describe ClimateMonth do
  it 'is valid from the factory' do
    expect(build(:climate_month)).to be_valid
  end

  it 'has one row for a cell and month' do
    create(:climate_month)
    expect(build(:climate_month)).not_to be_valid
  end

  it 'has a real month' do
    expect(build(:climate_month, month: 13)).not_to be_valid
  end
end
