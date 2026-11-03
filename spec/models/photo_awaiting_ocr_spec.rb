# frozen_string_literal: true

require 'rails_helper'

describe Photo, '.awaiting_ocr' do
  let(:seed) { create(:seed) }
  let(:photo) { create(:photo, owner: seed.owner) }

  def attach(item, label, text: nil)
    photo = create(:photo, owner: item.owner, ocr_text: text)
    item.photo_associations.create!(photo:, label:)
    photo
  end

  it 'has the photo of a packet with no text' do
    packet = attach(seed, 'back')
    expect(described_class.awaiting_ocr).to eq [packet]
  end

  it 'has the photo of a packet with only empty text' do
    packet = attach(seed, 'front', text: '')
    expect(described_class.awaiting_ocr).to eq [packet]
  end

  it 'leaves out a photo that has its text' do
    attach(seed, 'back', text: 'Sow by: December 2026')
    expect(described_class.awaiting_ocr).to be_empty
  end

  it 'reads the other side of a packet when one side has its text' do
    attach(seed, 'front', text: 'Sow by: December 2026')
    back = attach(seed, 'back')
    expect(described_class.awaiting_ocr).to eq [back]
  end

  it 'leaves out a photo that is not of the packet' do
    attach(seed, nil)
    expect(described_class.awaiting_ocr).to be_empty
  end

  it 'leaves out the photos of something that is not a seed' do
    attach(create(:job), 'before')
    expect(described_class.awaiting_ocr).to be_empty
  end
end
