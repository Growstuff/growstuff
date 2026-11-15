# frozen_string_literal: true

require 'rails_helper'

describe PhotoAssociationsController, '#destroy' do
  let(:planting) { create(:planting) }
  let(:photo) { create(:photo, owner: planting.owner) }

  before do
    photo.plantings << planting
    sign_in planting.owner
    delete photo_association_path(photo_id: photo.id, type: 'planting', id: planting.id)
  end

  it 'takes the photo off the planting' do
    expect(planting.reload.photos).to be_empty
  end

  it 'leaves the photo itself' do
    expect(Photo.exists?(photo.id)).to be true
  end

  it 'says what was removed' do
    expect(flash[:notice]).to eq 'Removed the photo from that planting. The photo is still on Growstuff.'
  end
end
