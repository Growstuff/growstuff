require 'spec_helper'

describe HarvestsController do

  login_member

  def valid_attributes
    {
      :owner_id => subject.current_member.id,
      :crop_id => FactoryGirl.create(:crop).id
    }
  end

  describe "GET index" do
    it "assigns all harvests as @harvests" do
      harvest = Harvest.create! valid_attributes
      get :index, {}
      assigns(:harvests).should eq([harvest])
    end
  end

  describe "GET show" do
    it "assigns the requested harvest as @harvest" do
      harvest = Harvest.create! valid_attributes
      get :show, {:id => harvest.to_param}
      assigns(:harvest).should eq(harvest)
    end
  end

  describe "GET new" do
    it "assigns a new harvest as @harvest" do
      get :new, {}
      assigns(:harvest).should be_a_new(Harvest)
    end
  end

  describe "GET edit" do
    it "assigns the requested harvest as @harvest" do
      harvest = Harvest.create! valid_attributes
      get :edit, {:id => harvest.to_param}
      assigns(:harvest).should eq(harvest)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Harvest" do
        expect {
          post :create, {:harvest => valid_attributes}
        }.to change(Harvest, :count).by(1)
      end

      it "assigns a newly created harvest as @harvest" do
        post :create, {:harvest => valid_attributes}
        assigns(:harvest).should be_a(Harvest)
        assigns(:harvest).should be_persisted
      end

      it "redirects to the created harvest" do
        post :create, {:harvest => valid_attributes}
        response.should redirect_to(Harvest.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved harvest as @harvest" do
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        post :create, {:harvest => { "crop_id" => "invalid value" }}
        assigns(:harvest).should be_a_new(Harvest)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        post :create, {:harvest => { "crop_id" => "invalid value" }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested harvest" do
        harvest = Harvest.create! valid_attributes
        # Assuming there are no other harvests in the database, this
        # specifies that the Harvest created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Harvest.any_instance.should_receive(:update_attributes).with({ "crop_id" => "1" })
        put :update, {:id => harvest.to_param, :harvest => { "crop_id" => "1" }}
      end

      it "assigns the requested harvest as @harvest" do
        harvest = Harvest.create! valid_attributes
        put :update, {:id => harvest.to_param, :harvest => valid_attributes}
        assigns(:harvest).should eq(harvest)
      end

      it "redirects to the harvest" do
        harvest = Harvest.create! valid_attributes
        put :update, {:id => harvest.to_param, :harvest => valid_attributes}
        response.should redirect_to(harvest)
      end
    end

    describe "with invalid params" do
      it "assigns the harvest as @harvest" do
        harvest = Harvest.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        put :update, {:id => harvest.to_param, :harvest => { "crop_id" => "invalid value" }}
        assigns(:harvest).should eq(harvest)
      end

      it "re-renders the 'edit' template" do
        harvest = Harvest.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        put :update, {:id => harvest.to_param, :harvest => { "crop_id" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested harvest" do
      harvest = Harvest.create! valid_attributes
      expect {
        delete :destroy, {:id => harvest.to_param}
      }.to change(Harvest, :count).by(-1)
    end

    it "redirects to the harvests list" do
      harvest = Harvest.create! valid_attributes
      delete :destroy, {:id => harvest.to_param}
      response.should redirect_to(harvests_url)
    end
  end

end
