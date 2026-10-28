# frozen_string_literal: true

require 'rails_helper'

describe PhotosHelper do
  describe '#packet_image_urls' do
    subject { helper.packet_image_urls(seed) }

    let(:seed) { create(:seed) }
    let(:front) { create(:photo, owner: seed.owner, fullsize_url: 'http://example.com/front.jpg') }
    let(:back) { create(:photo, owner: seed.owner, fullsize_url: 'http://example.com/back.jpg') }

    context 'with both sides, added back first' do
      before do
        seed.photo_associations.create!(photo: back, label: 'back')
        seed.photo_associations.create!(photo: front, label: 'front')
      end

      it { is_expected.to eq ['http://example.com/front.jpg', 'http://example.com/back.jpg'] }
    end

    context 'with a photo that is not of the packet' do
      before { seed.photo_associations.create!(photo: front) }

      it { is_expected.to eq [] }
    end
  end
end
