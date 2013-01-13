require 'spec_helper'

describe GardensController do

  login_member

  # This should return the minimal set of attributes required to create a valid
  # Garden. As you add validations to Garden, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {:name => 'My Garden', :owner_id => 1 }
  end

  # This should return the minimal set of values that should be in the session
  # in order to pass any filters (e.g. authentication) defined in
  # GardensController. Be sure to keep this updated too.
  def valid_session
    { }
  end

  describe "GET index" do
    it "assigns all gardens as @gardens" do
      gardens = Garden.all
      get :index, {}
      assigns(:gardens).should eq(gardens)
    end
  end

  describe "GET show" do
    it "assigns the requested garden as @garden" do
      garden = Garden.create! valid_attributes
      get :show, {:id => garden.to_param}
      assigns(:garden).should eq(garden)
    end
  end

  describe "GET new" do
    it "assigns a new garden as @garden" do
      get :new, {}
      assigns(:garden).should be_a_new(Garden)
    end
  end

  describe "GET edit" do
    it "assigns the requested garden as @garden" do
      garden = Garden.create! valid_attributes
      get :edit, {:id => garden.to_param}
      assigns(:garden).should eq(garden)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Garden" do
        expect {
          post :create, {:garden => valid_attributes}
        }.to change(Garden, :count).by(1)
      end

      it "assigns a newly created garden as @garden" do
        post :create, {:garden => valid_attributes}
        assigns(:garden).should be_a(Garden)
        assigns(:garden).should be_persisted
      end

      it "redirects to the created garden" do
        post :create, {:garden => valid_attributes}
        response.should redirect_to(Garden.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved garden as @garden" do
        # Trigger the behavior that occurs when invalid params are submitted
        Garden.any_instance.stub(:save).and_return(false)
        post :create, {:garden => {}}
        assigns(:garden).should be_a_new(Garden)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Garden.any_instance.stub(:save).and_return(false)
        post :create, {:garden => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested garden" do
        garden = Garden.create! valid_attributes
        # Assuming there are no other gardens in the database, this
        # specifies that the Garden created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Garden.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => garden.to_param, :garden => {'these' => 'params'}}
      end

      it "assigns the requested garden as @garden" do
        garden = Garden.create! valid_attributes
        put :update, {:id => garden.to_param, :garden => valid_attributes}
        assigns(:garden).should eq(garden)
      end

      it "redirects to the garden" do
        garden = Garden.create! valid_attributes
        put :update, {:id => garden.to_param, :garden => valid_attributes}
        response.should redirect_to(garden)
      end
    end

    describe "with invalid params" do
      it "assigns the garden as @garden" do
        garden = Garden.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Garden.any_instance.stub(:save).and_return(false)
        put :update, {:id => garden.to_param, :garden => {}}
        assigns(:garden).should eq(garden)
      end

      it "re-renders the 'edit' template" do
        garden = Garden.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Garden.any_instance.stub(:save).and_return(false)
        put :update, {:id => garden.to_param, :garden => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested garden" do
      garden = Garden.create! valid_attributes
      expect {
        delete :destroy, {:id => garden.to_param}
      }.to change(Garden, :count).by(-1)
    end

    it "redirects to the gardens list" do
      garden = Garden.create! valid_attributes
      delete :destroy, {:id => garden.to_param}
      response.should redirect_to(gardens_url)
    end
  end

end
