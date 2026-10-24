# frozen_string_literal: true

require 'rails_helper'

# Uploading a photo from your device, after the browser has sent the file
# straight to storage and has its signed id.
describe PhotosController do
  include ActiveJob::TestHelper

  let(:member) { create(:member) }
  let(:garden) { create(:garden, owner: member) }
  let(:blob) do
    ActiveStorage::Blob.create_and_upload!(io: file_fixture('garden_with_location.jpg').open,
                                           filename: 'garden.jpg', content_type: 'image/jpeg')
  end
  let(:photo_params) do
    { upload: blob.signed_id, title: 'Beans up', license_name: 'CC BY-SA 4.0', rights_confirmed: '1' }
  end

  before { sign_in member }

  describe '#create' do
    subject(:upload) { post photos_path(type: 'garden', id: garden.id), params: { photo: photo_params } }

    context 'with access to the photo library' do
      before { create(:approved_photo_library_access, member:) }

      it 'puts the photo on the garden' do
        upload
        expect(garden.photos.pluck(:title)).to eq ['Beans up']
      end

      it 'keeps the licence' do
        upload
        expect(garden.photos.first.license_url).to eq 'https://creativecommons.org/licenses/by-sa/4.0/'
      end

      it 'processes it' do
        upload
        expect(PhotoUploadJob).to have_been_enqueued
      end

      it 'goes back to the garden' do
        upload
        expect(response).to redirect_to(garden)
      end
    end

    context 'without confirming the right to share it' do
      before do
        create(:approved_photo_library_access, member:)
        photo_params[:rights_confirmed] = '0'
      end

      it 'adds no photo' do
        expect { upload }.not_to change(Photo, :count)
      end

      it 'says why' do
        upload
        expect(flash[:alert]).to include 'Rights confirmed must be accepted'
      end
    end

    context "with someone else's garden" do
      let(:garden) { create(:garden) }

      before { create(:approved_photo_library_access, member:) }

      it 'adds no photo' do
        expect { upload }.not_to change(Photo, :count)
      end
    end

    context 'without access to the photo library' do
      it 'adds no photo' do
        expect { upload }.not_to change(Photo, :count)
      end
    end
  end

  describe '#new' do
    subject(:page) do
      get new_photo_path(type: 'garden', id: garden.id)
      response.body
    end

    context 'with access to the photo library' do
      before { create(:approved_photo_library_access, member:) }

      it 'offers to upload' do
        expect(page).to include 'Upload photo'
      end

      it 'sends the file straight to storage' do
        expect(page).to include 'data-direct-upload-url'
      end
    end

    context 'without access to the photo library' do
      it 'offers to ask for it' do
        expect(page).to include 'ask for access to the photo library'
      end
    end

    context 'with a request waiting' do
      before { create(:photo_library_access, member:) }

      it 'says so' do
        expect(page).to include 'An admin will look at your request'
      end
    end
  end
end
