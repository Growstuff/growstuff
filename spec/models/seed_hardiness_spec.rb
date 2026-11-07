# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#hardiness' do
  it 'defaults to unknown' do
    expect(build(:seed).hardiness).to eq 'unknown'
  end

  it 'accepts a level' do
    expect(build(:seed, hardiness: 'half_hardy')).to be_valid
  end

  it 'rejects anything else' do
    expect(build(:seed, hardiness: 'very')).not_to be_valid
  end
end
