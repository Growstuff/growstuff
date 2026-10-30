# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociation, '.awaiting_text' do
  let(:seed) { create(:seed) }

  def attach(item, label)
    item.photo_associations.create!(photo: create(:photo, owner: item.owner), label:)
  end

  it 'has the photos of a packet whose seed has no text' do
    association = attach(seed, 'back')
    expect(described_class.awaiting_text).to eq [association]
  end

  it 'has the photos of a packet whose seed has only empty text' do
    seed.update!(packet_text: '')
    association = attach(seed, 'front')
    expect(described_class.awaiting_text).to eq [association]
  end

  it 'leaves out a seed that has its text' do
    attach(create(:seed, packet_text: 'Sow by: December 2026'), 'back')
    expect(described_class.awaiting_text).to be_empty
  end

  it 'leaves out a photo that is not of the packet' do
    attach(seed, nil)
    expect(described_class.awaiting_text).to be_empty
  end

  it 'leaves out the photos of something that is not a seed' do
    attach(create(:job), 'before')
    expect(described_class.awaiting_text).to be_empty
  end
end
