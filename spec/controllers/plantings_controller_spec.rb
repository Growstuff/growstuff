require 'spec_helper'

describe PlantingsController do

  login_member

  def valid_attributes
    {
      :garden_id => FactoryGirl.create(:garden, :owner => subject.current_member).id,
      :crop_id => FactoryGirl.create(:crop).id
    }
  end

  describe "GET index" do
    it "assigns all plantings as @plantings" do
      planting = Planting.create! valid_attributes
      get :index, {}
      assigns(:plantings).should eq([planting])
      assigns(:recent_plantings).should eq([planting])
    end
  end

  describe "GET show" do
    it "assigns the requested planting as @planting" do
      planting = Planting.create! valid_attributes
      get :show, {:id => planting.to_param}
      assigns(:planting).should eq(planting)
    end
  end

  describe "GET new" do
    it "assigns a new planting as @planting" do
      get :new, {}
      assigns(:planting).should be_a_new(Planting)
    end

    it "picks up crop from params" do
      crop = FactoryGirl.create(:crop)
      get :new, {:crop_id => crop.id}
      assigns(:crop).should eq(crop)
    end

    it "doesn't die if no crop specified" do
      get :new, {}
      assigns(:crop).should be_a_new(Crop)
    end

    it "picks up garden from params" do
      member = FactoryGirl.create(:member)
      garden = FactoryGirl.create(:garden, :owner => member)
      get :new, {:garden_id => garden.id}
      assigns(:garden).should eq(garden)
    end

    it "doesn't die if no garden specified" do
      get :new, {}
      assigns(:garden).should be_a_new(Garden)
    end

    it "sets the date of the planting to today" do
      get :new, {}
      assigns(:planting).planted_at.should == Date.today
    end

  end

  describe "GET edit" do
    it "assigns the requested planting as @planting" do
      planting = Planting.create! valid_attributes
      get :edit, {:id => planting.to_param}
      assigns(:planting).should eq(planting)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Planting" do
        expect {
          post :create, {:planting => valid_attributes}
        }.to change(Planting, :count).by(1)
      end

      it "assigns a newly created planting as @planting" do
        post :create, {:planting => valid_attributes}
        assigns(:planting).should be_a(Planting)
        assigns(:planting).should be_persisted
      end

      it "redirects to the created planting" do
        post :create, {:planting => valid_attributes}
        response.should redirect_to(Planting.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved planting as @planting" do
        # Trigger the behavior that occurs when invalid params are submitted
        Planting.any_instance.stub(:save).and_return(false)
        post :create, {:planting => {}}
        assigns(:planting).should be_a_new(Planting)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Planting.any_instance.stub(:save).and_return(false)
        post :create, {:planting => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested planting" do
        planting = Planting.create! valid_attributes
        # Assuming there are no other plantings in the database, this
        # specifies that the Planting created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Planting.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => planting.to_param, :planting => {'these' => 'params'}}
      end

      it "assigns the requested planting as @planting" do
        planting = Planting.create! valid_attributes
        put :update, {:id => planting.to_param, :planting => valid_attributes}
        assigns(:planting).should eq(planting)
      end

      it "redirects to the planting" do
        planting = Planting.create! valid_attributes
        put :update, {:id => planting.to_param, :planting => valid_attributes}
        response.should redirect_to(planting)
      end
    end

    describe "with invalid params" do
      it "assigns the planting as @planting" do
        planting = Planting.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Planting.any_instance.stub(:save).and_return(false)
        put :update, {:id => planting.to_param, :planting => {}}
        assigns(:planting).should eq(planting)
      end

      it "re-renders the 'edit' template" do
        planting = Planting.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Planting.any_instance.stub(:save).and_return(false)
        put :update, {:id => planting.to_param, :planting => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested planting" do
      planting = Planting.create! valid_attributes
      expect {
        delete :destroy, {:id => planting.to_param}
      }.to change(Planting, :count).by(-1)
    end

    it "redirects to the plantings list" do
      planting = Planting.create! valid_attributes
      delete :destroy, {:id => planting.to_param}
      response.should redirect_to(plantings_url)
    end
  end

end
