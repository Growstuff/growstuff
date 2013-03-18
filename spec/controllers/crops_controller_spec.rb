require 'spec_helper'

describe CropsController do

  login_member(:crop_wrangling_member)

  def valid_attributes
     { :system_name => "Tomato" }
  end

  describe "GET index" do
    it "assigns all crops as @crops" do
      crop = Crop.create! valid_attributes
      get :index, {}
      assigns(:crops).should eq([crop])
      assigns(:new_crops).should eq([crop])
    end
  end

  describe "GET RSS feed" do
    it "returns an RSS feed" do
      get :index, :format => "rss"
      response.should be_success
      response.should render_template("crops/index")
      response.content_type.should eq("application/rss+xml")
    end
  end

  describe "GET show" do
    it "assigns the requested crop as @crop" do
      crop = Crop.create! valid_attributes
      get :show, {:id => crop.to_param}
      assigns(:crop).should eq(crop)
    end
  end

  describe "GET new" do
    it "assigns a new crop as @crop" do
      get :new, {}
      assigns(:crop).should be_a_new(Crop)
    end
  end

  describe "GET edit" do
    it "assigns the requested crop as @crop" do
      crop = Crop.create! valid_attributes
      get :edit, {:id => crop.to_param}
      assigns(:crop).should eq(crop)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Crop" do
        expect {
          post :create, {:crop => valid_attributes}
        }.to change(Crop, :count).by(1)
      end

      it "assigns a newly created crop as @crop" do
        post :create, {:crop => valid_attributes}
        assigns(:crop).should be_a(Crop)
        assigns(:crop).should be_persisted
      end

      it "redirects to the created crop" do
        post :create, {:crop => valid_attributes}
        response.should redirect_to(Crop.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved crop as @crop" do
        # Trigger the behavior that occurs when invalid params are submitted
        Crop.any_instance.stub(:save).and_return(false)
        post :create, {:crop => {}}
        assigns(:crop).should be_a_new(Crop)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Crop.any_instance.stub(:save).and_return(false)
        post :create, {:crop => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested crop" do
        crop = Crop.create! valid_attributes
        # Assuming there are no other crops in the database, this
        # specifies that the Crop created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Crop.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => crop.to_param, :crop => {'these' => 'params'}}
      end

      it "assigns the requested crop as @crop" do
        crop = Crop.create! valid_attributes
        put :update, {:id => crop.to_param, :crop => valid_attributes}
        assigns(:crop).should eq(crop)
      end

      it "redirects to the crop" do
        crop = Crop.create! valid_attributes
        put :update, {:id => crop.to_param, :crop => valid_attributes}
        response.should redirect_to(crop)
      end
    end

    describe "with invalid params" do
      it "assigns the crop as @crop" do
        crop = Crop.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Crop.any_instance.stub(:save).and_return(false)
        put :update, {:id => crop.to_param, :crop => {}}
        assigns(:crop).should eq(crop)
      end

      it "re-renders the 'edit' template" do
        crop = Crop.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Crop.any_instance.stub(:save).and_return(false)
        put :update, {:id => crop.to_param, :crop => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested crop" do
      crop = Crop.create! valid_attributes
      expect {
        delete :destroy, {:id => crop.to_param}
      }.to change(Crop, :count).by(-1)
    end

    it "redirects to the crops list" do
      crop = Crop.create! valid_attributes
      delete :destroy, {:id => crop.to_param}
      response.should redirect_to(crops_url)
    end
  end

end
