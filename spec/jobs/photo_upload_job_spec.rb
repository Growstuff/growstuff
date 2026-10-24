# frozen_string_literal: true

require 'rails_helper'
require 'image_processing/vips'

describe PhotoUploadJob do
  subject(:perform) { described_class.perform_now(photo) }

  let(:photo) do
    Photo.build_upload(owner: create(:member), upload: fixture_file_upload(file, content_type),
                       title: 'Tomatoes', license_name: 'CC BY 4.0', rights_confirmed: true).tap(&:save!)
  end
  let(:file) { 'garden_with_location.jpg' }
  let(:content_type) { 'image/jpeg' }

  def stored(version)
    Vips::Image.new_from_buffer(photo.reload.public_send(:"#{version}_image").download, '')
  end

  context 'with a photo' do
    before { perform }

    it 'makes the full size version where its address says' do
      expect(photo.reload.fullsize_image.key).to eq PhotoLibrary.key(photo.source_id, :fullsize)
    end

    it 'makes the thumbnail where its address says' do
      expect(photo.reload.thumbnail_image.key).to eq PhotoLibrary.key(photo.source_id, :thumbnail)
    end

    it 'crops the thumbnail square' do
      expect([stored(:thumbnail).width, stored(:thumbnail).height]).to eq [300, 300]
    end

    it 'does not enlarge a small photo' do
      expect(stored(:fullsize).width).to eq 64
    end

    it 'removes where it was taken' do
      expect(stored(:fullsize).get_fields.grep(/gps/i)).to be_empty
    end

    it 'keeps when it was taken' do
      expect(photo.reload.date_taken).to eq Time.zone.local(2024, 5, 1, 10, 30)
    end

    it 'deletes the photo as sent' do
      expect(photo.reload.upload).not_to be_attached
    end
  end

  context 'with a transparent PNG' do
    let(:file) { 'transparent.png' }
    let(:content_type) { 'image/png' }

    before { perform }

    it 'makes a JPEG' do
      expect(photo.reload.fullsize_image.content_type).to eq 'image/jpeg'
    end
  end

  context 'with a file that only says it is a photo' do
    let(:file) { 'not_a_photo.jpg' }

    it 'deletes the photo' do
      perform
      expect(Photo.exists?(photo.id)).to be false
    end
  end

  context 'with a photo too big to process' do
    before { stub_const('PhotoLibrary::MAX_PIXELS', 100) }

    it 'deletes the photo' do
      perform
      expect(Photo.exists?(photo.id)).to be false
    end
  end

  context 'when run again' do
    before do
      perform
      photo.upload.attach(fixture_file_upload(file, content_type))
    end

    it 'replaces the versions' do
      expect { described_class.perform_now(photo) }.not_to raise_error
    end
  end
end
