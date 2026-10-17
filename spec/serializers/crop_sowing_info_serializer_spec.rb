# frozen_string_literal: true

require 'rails_helper'

describe CropSowingInfoSerializer do
  subject(:json) { described_class.new(crop, member:).as_json }

  let(:member) { create(:member) }
  let(:crop) do
    create(:crop, name: 'beetroot', description: 'A sweet root.', perennial: false, sun_requirements: 'full sun', row_spacing: 30)
  end

  it { is_expected.to include(name: 'beetroot', description: 'A sweet root.', perennial: false, row_spacing_cm: 30) }

  it 'counts what the member has grown' do
    create(:planting, crop:, owner: member, garden: member.gardens.first)
    expect(json[:your_plantings]).to eq 1
  end

  it 'counts the packets the member has' do
    create(:seed, crop:, owner: member)
    expect(json[:your_seeds]).to eq 1
  end

  it 'does not count another member\'s plantings as theirs' do
    create(:planting, crop:)
    expect(json[:your_plantings]).to eq 0
  end
end
