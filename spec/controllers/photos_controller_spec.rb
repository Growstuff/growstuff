require 'spec_helper'

describe PhotosController do

  login_member

  def valid_attributes
    {
      "owner_id" => "1",
      "flickr_photo_id" => 1,
      "thumbnail_url" => 'http://example.com',
      "fullsize_url" => 'http://example.com'
    }
  end

  def valid_session
    {}
  end

  describe "GET index" do
    it "assigns all photos as @photos" do
      photo = Photo.create! valid_attributes
      get :index, {}
      assigns(:photos).should eq([photo])
    end
  end

  describe "GET show" do
    it "assigns the requested photo as @photo" do
      photo = Photo.create! valid_attributes
      get :show, {:id => photo.to_param}
      assigns(:photo).should eq(photo)
    end
  end

  describe "GET new" do
    it "assigns the flickr auth as @flickr_auth" do
      @member = FactoryGirl.create(:member)
      sign_in @member
      @auth = FactoryGirl.create(:flickr_authentication, :member => @member)
      subject.stub(:login_to_flickr)
      subject.stub(:get_photos) { [FactoryGirl.create(:photo)] }
      get :new, {}
      assigns(:flickr_auth).should be_an_instance_of(Authentication)
    end

    it "assigns a new photo as @photo" do
      get :new, {}
      assigns(:photo).should be_a_new(Photo)
    end
  end

  describe "GET edit" do
    it "assigns the requested photo as @photo" do
      photo = Photo.create! valid_attributes
      get :edit, {:id => photo.to_param}
      assigns(:photo).should eq(photo)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Photo" do
        expect {
          post :create, {:photo => valid_attributes}
        }.to change(Photo, :count).by(1)
      end

      it "assigns a newly created photo as @photo" do
        post :create, {:photo => valid_attributes}
        assigns(:photo).should be_a(Photo)
        assigns(:photo).should be_persisted
      end

      it "redirects to the created photo" do
        post :create, {:photo => valid_attributes}
        response.should redirect_to(Photo.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved photo as @photo" do
        # Trigger the behavior that occurs when invalid params are submitted
        Photo.any_instance.stub(:save).and_return(false)
        post :create, {:photo => { "owner_id" => "invalid value" }}
        assigns(:photo).should be_a_new(Photo)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Photo.any_instance.stub(:save).and_return(false)
        post :create, {:photo => { "owner_id" => "invalid value" }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested photo" do
        photo = Photo.create! valid_attributes
        # Assuming there are no other photos in the database, this
        # specifies that the Photo created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Photo.any_instance.should_receive(:update_attributes).with({ "owner_id" => "1" })
        put :update, {:id => photo.to_param, :photo => { "owner_id" => "1" }}
      end

      it "assigns the requested photo as @photo" do
        photo = Photo.create! valid_attributes
        put :update, {:id => photo.to_param, :photo => valid_attributes}
        assigns(:photo).should eq(photo)
      end

      it "redirects to the photo" do
        photo = Photo.create! valid_attributes
        put :update, {:id => photo.to_param, :photo => valid_attributes}
        response.should redirect_to(photo)
      end
    end

    describe "with invalid params" do
      it "assigns the photo as @photo" do
        photo = Photo.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Photo.any_instance.stub(:save).and_return(false)
        put :update, {:id => photo.to_param, :photo => { "owner_id" => "invalid value" }}
        assigns(:photo).should eq(photo)
      end

      it "re-renders the 'edit' template" do
        photo = Photo.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Photo.any_instance.stub(:save).and_return(false)
        put :update, {:id => photo.to_param, :photo => { "owner_id" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested photo" do
      photo = Photo.create! valid_attributes
      expect {
        delete :destroy, {:id => photo.to_param}
      }.to change(Photo, :count).by(-1)
    end

    it "redirects to the photos list" do
      photo = Photo.create! valid_attributes
      delete :destroy, {:id => photo.to_param}
      response.should redirect_to(photos_url)
    end
  end

end
