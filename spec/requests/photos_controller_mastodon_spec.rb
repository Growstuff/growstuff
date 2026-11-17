# frozen_string_literal: true

require 'rails_helper'

describe PhotosController do
  include Devise::Test::IntegrationHelpers

  let(:member) { create(:member) }
  let(:job) { create(:job, owner: member) }
  let!(:authentication) { create(:mastodon_authentication, member:, uid: '111@photos.example') }
  let(:resolver) { class_double(Resolv, getaddresses: ['93.184.216.34']) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:status) do
    { id: '123', account: { id: '111' }, visibility: 'public', url: 'https://photos.example/@alice/123',
      media_attachments: [{ id: '456', type: 'image', url: 'https://cdn.example/image.jpg',
                            preview_url: 'https://cdn.example/small.jpg', description: 'Tomatoes' }] }
  end
  let(:photo_params) { { source: 'mastodon', source_id: '456', status_id: '123', license_accepted: true } }

  around { |example| VCR.turned_off { example.run } }

  before do
    sign_in member
    allow(MastodonPhotoSource).to receive(:new).and_wrap_original do |original, auth|
      original.call(auth, resolver:, adapter: [:test, stubs])
    end
    stubs.get('/api/v1/accounts/111/statuses') { [200, {}, [status].to_json] }
    stubs.get('/api/v1/statuses/123') { [200, {}, status.to_json] }
  end

  def add_photo(format: :json, account_id: authentication.id)
    post photos_path(format:), params: { type: 'job', id: job.id, label: 'before', authentication_id: account_id, photo: photo_params }
  end

  describe 'listing photos' do
    it 'offers the connected accounts in the JSON picker' do
      get new_photo_path(format: :json), params: { type: 'job', id: job.id, source: 'mastodon' }
      expect(response.parsed_body['accounts'].pluck('id')).to eq [authentication.id]
    end

    it 'renders an unchecked required licence checkbox without JavaScript' do
      get new_photo_path, params: { type: 'job', id: job.id, source: 'mastodon' }
      expect(response.parsed_body.at_css('input[name="photo[license_accepted]"][required]:not([checked])')).to be_present
    end

    it 'offers Mastodon from the Flickr page without JavaScript' do
      get new_photo_path, params: { type: 'job', id: job.id }
      expect(response.parsed_body.at_css('a[href*="source=mastodon"]')).to be_present
    end

    context 'without a connected Mastodon account' do
      before { authentication.destroy! }

      it 'offers a connection rather than failing' do
        get new_photo_path(format: :json), params: { type: 'job', id: job.id, source: 'mastodon' }
        expect(response.parsed_body['state']).to eq 'connect'
      end
    end
  end

  describe 'adding a photo' do
    it 'creates a hosted photo' do
      expect { add_photo }.to change(Photo, :count).by(1)
    end

    it 'records the licence selected at import' do
      add_photo
      expect(job.photos.first.license_url).to eq MastodonPhotoSource::LICENSE_URL
    end

    it 'preserves the association label' do
      add_photo
      expect(job.photo_associations.first.label).to eq 'before'
    end

    it 'returns the created photo' do
      add_photo
      expect(response).to have_http_status(:created)
    end

    it 'imports without JavaScript' do
      add_photo(format: :html)
      expect(response).to redirect_to(photo_path(job.photos.first))
    end

    it 'does not duplicate an imported photo' do
      add_photo
      expect { add_photo }.not_to change(Photo, :count)
    end

    context 'without licence consent' do
      before { photo_params.delete(:license_accepted) }

      it 'does not create a photo' do
        expect { add_photo }.not_to change(Photo, :count)
      end

      it 'rejects the JSON request' do
        add_photo
        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the non-JavaScript user to the picker' do
        add_photo(format: :html)
        path = new_photo_path(type: 'job', id: job.id, label: 'before', source: 'mastodon', authentication_id: authentication.id)
        expect(response).to redirect_to(path)
      end
    end

    context 'with forged metadata' do
      before { photo_params.merge!(fullsize_url: 'https://evil.example/forged.jpg', license_name: 'CC0') }

      it 'uses metadata fetched from the source' do
        add_photo
        expect(job.photos.first.fullsize_url).to eq 'https://cdn.example/image.jpg'
      end
    end

    context 'when the post is no longer public' do
      before { status[:visibility] = 'private' }

      it 'does not create a photo' do
        expect { add_photo }.not_to change(Photo, :count)
      end
    end

    context 'with another member account' do
      let(:other_authentication) { create(:mastodon_authentication) }

      it 'does not permit importing from that account' do
        add_photo(account_id: other_authentication.id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context 'with another member destination' do
      let(:job) { create(:job) }

      it 'does not create a photo' do
        expect { add_photo }.not_to change(Photo, :count)
      end
    end
  end
end
