# frozen_string_literal: true

require 'rails_helper'

describe PhotoLibraryFilesController do
  let(:public_blob) do
    ActiveStorage::Blob.create_and_upload!(io: StringIO.new('jpeg'), filename: 'fullsize.jpg', key: 'photos/abc/fullsize.jpg')
  end
  let(:private_blob) { ActiveStorage::Blob.create_and_upload!(io: StringIO.new('jpeg'), filename: 'sent.jpg') }

  it 'shows a version made for showing' do
    get "/photo_library/#{public_blob.key.delete_prefix('photos/')}"
    expect(response).to redirect_to(%r{/rails/active_storage/blobs/})
  end

  it 'does not show a photo as sent' do
    get "/photo_library/#{private_blob.key}"
    expect(response).to have_http_status(:not_found)
  end
end
