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

  context 'without a photo of that side' do
    before { seed.photo_associations.where(label: 'back').destroy_all }

    it('is nothing') { expect(seed.packet_photo('back')).to be_nil }
  end
end
