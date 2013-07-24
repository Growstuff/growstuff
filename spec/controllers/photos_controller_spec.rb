require 'spec_helper'

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
      @auth = FactoryGirl.create(:flickr_authentication, :member => @member)
      get :new, {}
      assigns(:flickr_auth).should be_an_instance_of(Authentication)
    end

    it "assigns a planting id" do
      get :new, { :planting_id => 5 }
      assigns(:planting_id).should eq "5"
    end

    it "assigns the current set as @current_set" do
      get :new, { :set => 'foo' }
      assigns(:current_set).should eq "foo"
    end

  end

  describe "POST create" do
    before(:each) do
      Photo.any_instance.stub(:flickr_metadata).and_return( {
        :title => "A Heartbreaking work of staggering genius",
        :license_name => "CC-BY",
        :license_url => "http://example.com/aybpl",
        :thumbnail_url => "http://example.com/thumb.jpg",
        :fullsize_url => "http://example.com/full.jpg",
        :link_url => "http://example.com"
      })
    end

    describe "with valid params" do

      it "attaches the photo to a planting" do
        member = FactoryGirl.create(:member)
        controller.stub(:current_member) { member }
        garden = FactoryGirl.create(:garden, :owner => member)
        planting = FactoryGirl.create(:planting, :garden => garden)
        photo = FactoryGirl.create(:photo, :owner => member)
        post :create, {:photo => { :flickr_photo_id => photo.flickr_photo_id },
          :planting_id => planting.id }
        Photo.last.plantings.first.should eq planting
      end

      it "doesn't attach a photo to a planting twice" do
        member = FactoryGirl.create(:member)
        controller.stub(:current_member) { member }
        garden = FactoryGirl.create(:garden, :owner => member)
        planting = FactoryGirl.create(:planting, :garden => garden)
        photo = FactoryGirl.create(:photo, :owner => member)
        post :create, {:photo => { :flickr_photo_id => photo.flickr_photo_id },
          :planting_id => planting.id }
        post :create, {:photo => { :flickr_photo_id => photo.flickr_photo_id },
          :planting_id => planting.id }
        Photo.last.plantings.count.should eq 1
      end
    end

    describe "for the second time" do
      it "does not add a photo twice" do
        expect {
          post :create, {:photo => { :flickr_photo_id => 1 } }
        }.to change(Photo, :count).by(1)
        expect {
          post :create, {:photo => { :flickr_photo_id => 1 } }
        }.to change(Photo, :count).by(0)
      end
    end

    describe "with matching owners" do
      it "creates the planting/photo link" do
        member = FactoryGirl.create(:member)
        controller.stub(:current_member) { member }
        garden = FactoryGirl.create(:garden, :owner => member)
        planting = FactoryGirl.create(:planting, :garden => garden)
        photo = FactoryGirl.create(:photo, :owner => member)
        post :create, {:photo => { :flickr_photo_id => photo.flickr_photo_id },
          :planting_id => planting.id }
        Photo.last.plantings.first.should eq planting
      end
    end

    describe "with mismatched owners" do
      it "creates the planting/photo link" do
        # members will be auto-created, and different
        planting = FactoryGirl.create(:planting)
        photo = FactoryGirl.create(:photo)
        post :create, {:photo => { :flickr_photo_id => photo.flickr_photo_id },
          :planting_id => planting.id }
        Photo.last.plantings.first.should_not eq planting
      end
    end
  end
end
