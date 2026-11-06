# frozen_string_literal: true

require 'rails_helper'

describe Seed, '#packet_photo' do
  let(:seed) { create(:seed) }
  let(:front) { create(:photo, owner: seed.owner) }
  let(:back) { create(:photo, owner: seed.owner) }

  before do
    seed.photo_associations.create!(photo: front, label: 'front')
    seed.photo_associations.create!(photo: back, label: 'back')
    seed.photo_associations.create!(photo: create(:photo, owner: seed.owner))
  end

  it('is the front') { expect(seed.packet_photo('front')).to eq front }
  it('is the back') { expect(seed.packet_photo('back')).to eq back }

  context 'with the front photographed again' do
    let(:newer_front) { create(:photo, owner: seed.owner) }

    before { seed.photo_associations.create!(photo: newer_front, label: 'front') }

    it('is the newer photo') { expect(seed.packet_photo('front')).to eq newer_front }
  end

  context 'without a photo of that side' do
    before { seed.photo_associations.where(label: 'back').destroy_all }

    it('is nothing') { expect(seed.packet_photo('back')).to be_nil }
  end

  describe '#label_of' do
    it('is front for the front') { expect(seed.reload.label_of(front)).to eq 'front' }
    it('is back for the back') { expect(seed.reload.label_of(back)).to eq 'back' }

    it('is nothing for a photo that is not of the packet') do
      expect(seed.reload.label_of(seed.photos.reject { |photo| [front, back].include?(photo) }.first)).to be_nil
    end

    it('is nothing for a photo that is not of this seed') do
      expect(seed.reload.label_of(create(:photo, owner: seed.owner))).to be_nil
    end
  end
end
