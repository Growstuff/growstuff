# frozen_string_literal: true

require 'rails_helper'

describe Photo do
  include ActiveJob::TestHelper

  subject(:photo) do
    described_class.build_upload(owner: create(:member), upload:, title: 'Tomatoes', license_name: 'CC-BY')
  end

  let(:upload) { fixture_file_upload('garden_with_location.jpg', 'image/jpeg') }

  describe '.build_upload' do
    it 'is an upload' do
      expect(photo).to be_uploaded
    end

    it 'shows its full size version from the public part of the library' do
      expect(photo.fullsize_url).to end_with "/photo_library/#{photo.source_id}/fullsize.jpg"
    end

    it 'shows its thumbnail from the public part of the library' do
      expect(photo.thumbnail_url).to end_with "/photo_library/#{photo.source_id}/thumbnail.jpg"
    end

    it 'is valid' do
      expect(photo).to be_valid
    end
  end

  context 'when saved' do
    before { photo.save! }

    it 'links to its own page' do
      expect(photo.reload.link_url).to end_with "/photos/#{photo.id}"
    end

    it 'is processed in the background' do
      expect(PhotoUploadJob).to have_been_enqueued.with(photo)
    end
  end

  context 'without a file' do
    subject(:photo) { described_class.new(owner: create(:member), source: 'upload', title: 'T', license_name: 'CC-BY') }

    it 'is invalid' do
      expect(photo.tap(&:valid?).errors[:upload]).to be_present
    end
  end

  context 'with a file that is not a photo' do
    let(:upload) { fixture_file_upload('not_a_photo.jpg', 'text/plain') }

    it 'is invalid' do
      expect(photo.tap(&:valid?).errors[:upload]).to include 'must be a JPEG, PNG, WebP or HEIC photo'
    end
  end

  context 'with a file that is too big' do
    before { allow(photo.upload.blob).to receive(:byte_size).and_return(PhotoLibrary::MAX_FILE_SIZE + 1) }

    it 'is invalid' do
      expect(photo.tap(&:valid?).errors[:upload]).to include 'must be no bigger than 20 MB'
    end
  end

  context 'when linked from Flickr' do
    subject(:photo) { build(:photo) }

    it 'needs no file' do
      expect(photo).to be_valid
    end
  end
end
