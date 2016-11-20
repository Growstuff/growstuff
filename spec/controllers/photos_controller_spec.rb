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
    member = FactoryGirl.create(:member)
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
    before(:each) do
      @member = FactoryGirl.create(:member)
      sign_in @member
      @member.stub(:flickr_photos) { [[], 0] }
      @member.stub(:flickr_sets) { { "foo" => "bar" } }
      controller.stub(:current_member) { @member }
    end

    it "assigns the flickr auth as @flickr_auth" do
      @auth = FactoryGirl.create(:flickr_authentication, member: @member)
      get :new, {}
      assigns(:flickr_auth).should be_an_instance_of(Authentication)
    end

    it "assigns a planting id" do
      get :new, type: "planting", id: 5
      assigns(:id).should eq "5"
      assigns(:type).should eq "planting"
      expect(flash[:alert]).not_to be_present
    end

    it "assigns a harvest id" do
      get :new, type: "harvest", id: 5
      assigns(:id).should eq "5"
      assigns(:type).should eq "harvest"
      expect(flash[:alert]).not_to be_present
    end

    it "assigns a garden id" do
      get :new, type: "garden", id: 5
      assigns(:id).should eq "5"
      assigns(:type).should eq "garden"
      expect(flash[:alert]).not_to be_present
    end

    it "assigns the current set as @current_set" do
      get :new, set: 'foo'
      assigns(:current_set).should eq "foo"
      expect(flash[:alert]).not_to be_present
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

    describe "with valid params" do
      let(:member) { FactoryGirl.create(:member) }
      let(:garden) { FactoryGirl.create(:garden, owner: member) }
      let(:planting) { FactoryGirl.create(:planting, garden: garden, owner: member) }
      let(:harvest) { FactoryGirl.create(:harvest, owner: member) }
      let(:photo) { FactoryGirl.create(:photo, owner: member) }

      before { controller.stub(:current_member) { member } }
      it "attaches the photo to a planting" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).not_to be_present
        Photo.last.plantings.first.should eq planting
      end

      it "doesn't attach a photo to a planting twice" do
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).not_to be_present
        Photo.last.plantings.size.should eq 1
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
        comment = FactoryGirl.create(:comment)
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
      it "creates the planting/photo link" do
        member = FactoryGirl.create(:member)
        controller.stub(:current_member) { member }
        garden = FactoryGirl.create(:garden, owner: member)
        planting = FactoryGirl.create(:planting, garden: garden, owner: member)
        photo = FactoryGirl.create(:photo, owner: member)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).not_to be_present
        Photo.last.plantings.first.should eq planting
      end

      it "creates the harvest/photo link" do
        member = FactoryGirl.create(:member)
        controller.stub(:current_member) { member }
        harvest = FactoryGirl.create(:harvest, owner: member)
        photo = FactoryGirl.create(:photo, owner: member)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        expect(flash[:alert]).not_to be_present
        Photo.last.harvests.first.should eq harvest
      end
    end

    describe "with mismatched owners" do
      let(:photo) { FactoryGirl.create(:photo) }
      it "does not create the planting/photo link" do
        # members will be auto-created, and different
        planting = FactoryGirl.create(:planting)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "planting", id: planting.id
        expect(flash[:alert]).to be_present
        Photo.last.plantings.first.should_not eq planting
      end

      it "does not create the harvest/photo link" do
        # members will be auto-created, and different
        harvest = FactoryGirl.create(:harvest)
        post :create, photo: { flickr_photo_id: photo.flickr_photo_id }, type: "harvest", id: harvest.id
        expect(flash[:alert]).to be_present
        Photo.last.harvests.first.should_not eq harvest
      end
    end
  end
end
