# frozen_string_literal: true

require 'rails_helper'

describe NeighboursHelper do
  describe '#own_photo_url' do
    let(:planting) { create(:planting) }

    it 'is the photo on the planting' do
      photo = create(:photo, owner: planting.owner)
      planting.photos << photo
      expect(helper.own_photo_url(planting)).to eq photo.fullsize_url
    end

    it 'is nothing when only the crop has a photo' do
      other = create(:planting, crop: planting.crop)
      other.photos << create(:photo, owner: other.owner)
      expect(planting.crop.photos).to be_present
      expect(helper.own_photo_url(planting)).to be_nil
    end

    it 'is nothing for a record that cannot have photos' do
      expect(helper.own_photo_url(planting.garden.owner)).to be_nil
    end
  end

  describe '#image_of' do
    it 'says what the picture is of' do
      planting = create(:planting)
      expect(helper.image_of('x.jpg', planting)).to include(link: planting, label: "A #{planting.crop.name} planting")
    end

    it 'has no label for a photo that is not of anything' do
      expect(helper.image_of('x.jpg', create(:photo))[:label]).to be_nil
    end
  end
end
