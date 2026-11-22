# frozen_string_literal: true

require 'rails_helper'

describe GardenFormSerializer do
  subject(:json) { described_class.new(garden, member: garden.owner).as_json }

  let(:garden) { create(:garden, frost_safe: true) }

  it 'gives whether the garden is safe from frost' do
    expect(json[:garden][:frost_safe]).to be true
  end

  it 'gives the words for the frost checkbox' do
    expect(json.values_at(:frost_safe_label, :frost_safe_help)).to all(be_present)
  end
end
