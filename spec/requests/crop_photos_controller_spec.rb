# frozen_string_literal: true

require 'rails_helper'

describe CropPhotosController do
  let(:crop) { create(:tomato) }
  let(:wrangler) { create(:crop_wrangling_member) }
  let!(:cropbot) { create(:member, login_name: 'cropbot') }
  let(:attributes) do
    { source: 'flickr', source_id: '12345', title: 'A tomato', license_name: 'Attribution License',
      license_url: 'https://creativecommons.org/licenses/by/2.0/', thumbnail_url: 'https://example.com/q.jpg',
      fullsize_url: 'https://example.com/z.jpg', link_url: 'https://www.flickr.com/photos/pat/12345',
      date_taken: '2020-01-02 03:04:05', author_name: 'Pat Photo', author_url: 'https://www.flickr.com/photos/pat/' }
  end
  let(:photo) { Photo.find_by(source_id: '12345') }
  let(:flickr_photo) { instance_double(FlickrPublicPhoto, attributes: attributes) }

  before do
    allow(FlickrPublicPhoto).to receive(:new).and_return(flickr_photo)
  end

  describe 'POST create' do
    context 'when a crop wrangler adds a harvest photo' do
      before do
        sign_in wrangler
        post crop_photos_path(crop), params: { url: 'https://www.flickr.com/photos/pat/12345/', kind: 'harvest' }
      end

      it { expect(response).to redirect_to(crop_path(crop)) }
      it { expect(photo.crops).to eq [crop] }
      it { expect(photo.photo_associations.first.label).to eq 'harvest' }
      it { expect(photo.owner).to eq cropbot }
      it { expect(Photo.shown_as(Harvest)).to eq [photo] }
      it { expect(Photo.shown_as(Crop)).to be_empty }
    end

    context 'when the photo shows the plant itself' do
      before do
        sign_in wrangler
        post crop_photos_path(crop), params: { url: 'https://www.flickr.com/photos/pat/12345/', kind: '' }
      end

      it { expect(Photo.shown_as(Crop)).to eq [photo] }
    end

    context 'when Flickr refuses the photo' do
      before do
        allow(flickr_photo).to receive(:attributes).and_raise(FlickrPublicPhoto::Rejected, :not_public)
        sign_in wrangler
        post crop_photos_path(crop), params: { url: 'https://www.flickr.com/photos/pat/12345/' }
      end

      it { expect(flash[:alert]).to eq I18n.t('crop_photos.create.not_public') }
      it { expect(Photo.count).to eq 0 }
    end

    context 'when not a crop wrangler' do
      before do
        sign_in create(:member)
        post crop_photos_path(crop), params: { url: 'https://www.flickr.com/photos/pat/12345/' }
      end

      it { expect(Photo.count).to eq 0 }
    end
  end

  describe 'GET new' do
    before do
      allow(FlickrPublicPhoto).to receive(:search).with('tomato', page: 1).and_return(
        [{ title: 'Red', owner_name: 'Pat', thumbnail_url: 'https://example.com/q.jpg', url: 'https://www.flickr.com/photos/pat/1' }]
      )
      sign_in wrangler
      get new_crop_photo_path(crop)
    end

    it { expect(response.body).to include 'https://www.flickr.com/photos/pat/1' }
  end

  describe 'photo page' do
    before do
      sign_in wrangler
      post crop_photos_path(crop), params: { url: 'x' }
      get photo_path(photo)
    end

    it { expect(response.body).to include 'Pat Photo' }
    it { expect(response.body).to include 'Attribution License' }
  end
end
