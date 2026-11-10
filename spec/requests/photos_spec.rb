# frozen_string_literal: true

require 'rails_helper'

describe "Photos" do
  include Devise::Test::IntegrationHelpers

  describe "GET /photos/:id/edit" do
    let(:photo) { create(:photo) }

    describe "shows the owner a form to save changes to their photo" do
      before do
        sign_in photo.owner
        get edit_photo_path(photo)
      end

      it { expect(response).to have_http_status(:ok) }
      it { expect(Capybara.string(response.body)).to have_button('Save') }
    end
  end

  describe "PATCH /photos/:id" do
    let(:photo) { create(:photo, title: 'Old', license_name: 'CC BY 2.0') }

    before do
      sign_in photo.owner
      patch photo_path(photo), params: { photo: { title: 'New', license_name: 'Public domain' } }
    end

    it "changes the title" do
      expect(photo.reload.title).to eq 'New'
    end

    it "leaves the licence as Flickr has it" do
      expect(photo.reload.license_name).to eq 'CC BY 2.0'
    end
  end

  describe "POST /photos/:id/refresh" do
    let(:photo) { create(:photo, title: 'My title', license_name: 'All rights reserved', license_url: nil) }
    let(:fresh) do
      { thumbnail_url: 'https://example.com/new_q.jpg', fullsize_url: 'https://example.com/new_z.jpg',
        link_url: photo.link_url, license_name: 'Attribution License',
        license_url: 'https://creativecommons.org/licenses/by/2.0/', date_taken: '2020-01-02 03:04:05',
        title: 'Flickr title' }
    end
    let(:flickr_photo) { instance_double(FlickrPublicPhoto, attributes: fresh) }

    before { allow(FlickrPublicPhoto).to receive(:new).and_return(flickr_photo) }

    context "when the owner refreshes it" do
      before do
        sign_in photo.owner
        post refresh_photo_path(photo)
      end

      it { expect(response).to redirect_to(photo_path(photo)) }
      it { expect(photo.reload.license_name).to eq 'Attribution License' }
      it { expect(photo.reload.title).to eq 'My title' }
    end

    context "when another member tries" do
      before do
        sign_in create(:member)
        post refresh_photo_path(photo)
      end

      it { expect(photo.reload.license_name).to eq 'All rights reserved' }
    end

    context "when Flickr no longer shares the photo" do
      before do
        allow(flickr_photo).to receive(:attributes).and_raise(FlickrPublicPhoto::Rejected, :not_public)
        sign_in photo.owner
        post refresh_photo_path(photo)
      end

      it { expect(flash[:alert]).to eq I18n.t('photos.refresh.not_public') }
      it { expect(photo.reload.license_name).to eq 'All rights reserved' }
    end
  end

  describe "GET /photos" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get photos_path
      expect(response.status).to be(200)
    end
  end
end
