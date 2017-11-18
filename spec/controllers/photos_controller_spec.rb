# frozen_string_literal: true
## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project.
## We no longer write new view and controller tests, but instead write
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara).
## These test the full stack, behaving as a browser, and require less complicated setup
## to run. Please feel free to delete old view/controller tests as they are reimplemented
## in feature tests.
##
## If you submit a pull request containing new view or controller tests, it will not be
## merged.

require 'rails_helper'

describe PhotosController do
  login_member

  def valid_attributes
    member = FactoryBot.create(:member)
    {
      "owner_id" => member.id,
      "flickr_photo_id" => 1,
      "title" => "Photo",
      "license_name" => "CC-BY",
      "thumbnail_url" => 'http://example.com/thumb.jpg',
      "fullsize_url" => 'http://example.com/full.jpg',
      "link_url" => 'http://example.com'
    }
  end

  def valid_session
    {}
  end

  describe "GET new" do
    let(:tomato) { FactoryBot.create(:tomato) }
    let(:planting) { FactoryBot.create(:planting, crop: tomato, owner: member) }
    let(:garden) { FactoryBot.create(:garden, owner: member) }
    let(:harvest) { FactoryBot.create(:harvest, owner: member) }
    let(:member) { FactoryBot.create(:member) }
    let!(:auth) { FactoryBot.create(:flickr_authentication, member: member) }

    before(:each) do
      sign_in member
      member.stub(:flickr_photos) { [[], 0] }
      member.stub(:flickr_sets) { { "foo" => "bar" } }
      controller.stub(:current_member) { member }
    end

    describe "planting photos" do
      before(:each) { get :new, type: "planting", id: planting.id }
      it { assigns(:flickr_auth).should be_an_instance_of(Authentication) }
      it { assigns(:id).should eq planting.id.to_s }
      it { assigns(:type).should eq "planting" }
      it { expect(flash[:alert]).not_to be_present }
      it { expect(flash[:alert]).not_to be_present }
    end

    describe "harvest photos" do
      before { get :new, type: "harvest", id: harvest.id }
      it { assigns(:id).should eq harvest.id.to_s }
      it { assigns(:type).should eq "harvest" }
      it { expect(flash[:alert]).not_to be_present }
    end

    describe "garden photos" do
      before { get :new, type: "garden", id: garden.id }
      it { assigns(:id).should eq garden.id.to_s }
      it { assigns(:type).should eq "garden" }
      it { expect(flash[:alert]).not_to be_present }
    end
  end

  describe "POST create" do
    before(:each) do
      Photo.any_instance.stub(:flickr_metadata).and_return(title: "A Heartbreaking work of staggering genius",
                                                           license_name: "CC-BY",
                                                           license_url: "http://example.com/aybpl",
                                                           thumbnail_url: "http://example.com/thumb.jpg",
                                                           fullsize_url: "http://example.com/full.jpg",
                                                           link_url: "http://example.com")
    end

    let(:member) { FactoryBot.create(:member) }
    let(:garden) { FactoryBot.create(:garden, owner: member) }
    let(:planting) { FactoryBot.create(:planting, garden: garden, owner: member) }
    let(:harvest) { FactoryBot.create(:harvest, owner: member) }
    let(:photo) { FactoryBot.create(:photo, owner: member) }
    describe "with valid params" do
      before { controller.stub(:current_member) { member } }
      it "attaches the photo to a planting" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).not_to be_present
        Photo.last.plantings.first.should eq planting
      end

      describe "doesn't attach a photo to a planting twice" do
        before do
          post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
          post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        end
        it { expect(flash[:alert]).not_to be_present }
        it { expect(Photo.last.plantings.size).to eq 1 }
      end

      it "attaches the photo to a harvest" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        expect(flash[:alert]).not_to be_present
        Photo.last.harvests.first.should eq harvest
      end

      it "doesn't attach a photo to a harvest twice" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        expect(flash[:alert]).not_to be_present
        Photo.last.harvests.size.should eq 1
      end

      it "doesn't attach photo to a comment" do
        comment = FactoryBot.create(:comment)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "comment", id: comment.id
        expect(flash[:alert]).to be_present
      end
    end

    describe "for the second time" do
      it "does not add a photo twice" do
        expect do
          post :create, photo: { flickr_photo_id: 1 }
        end.to change(Photo, :count).by(1)
        expect do
          post :create, photo: { flickr_photo_id: 1 }
        end.to change(Photo, :count).by(0)
      end
    end

    describe "with matching owners" do
      before { controller.stub(:current_member) { member } }
      it "creates the planting/photo link" do
        planting = FactoryBot.create(:planting, garden: garden, owner: member)
        photo = FactoryBot.create(:photo, owner: member)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).not_to be_present
        Photo.last.plantings.first.should eq planting
      end

      it "creates the harvest/photo link" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        expect(flash[:alert]).not_to be_present
        Photo.last.harvests.first.should eq harvest
      end
    end

    describe "with mismatched owners" do
      let(:photo) { FactoryBot.create(:photo) }
      it "does not create the planting/photo link" do
        # members will be auto-created, and different
        another_planting = FactoryBot.create(:planting)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: another_planting.id
        expect(flash[:alert]).to be_present
        Photo.last.plantings.first.should_not eq another_planting
      end

      it "does not create the harvest/photo link" do
        # members will be auto-created, and different
        another_harvest = FactoryBot.create(:harvest)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: another_harvest.id
        expect(flash[:alert]).to be_present
        Photo.last.harvests.first.should_not eq another_harvest
      end
    end
  end
end
