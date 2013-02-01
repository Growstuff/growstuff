require 'spec_helper'

describe ScientificNamesController do

  login_member

  def valid_attributes
    { :scientific_name => 'Solanum lycopersicum', :crop_id => 1 }
  end

  describe "GET index" do
    it "assigns all scientific_names as @scientific_names" do
      scientific_name = ScientificName.create! valid_attributes
      get :index, {}
      assigns(:scientific_names).should eq([scientific_name])
    end
  end

  describe "GET show" do
    it "assigns the requested scientific_name as @scientific_name" do
      scientific_name = ScientificName.create! valid_attributes
      get :show, {:id => scientific_name.to_param}
      assigns(:scientific_name).should eq(scientific_name)
    end
  end

  describe "GET new" do
    it "assigns a new scientific_name as @scientific_name" do
      get :new, {}
      assigns(:scientific_name).should be_a_new(ScientificName)
    end
  end

  describe "GET edit" do
    it "assigns the requested scientific_name as @scientific_name" do
      scientific_name = ScientificName.create! valid_attributes
      get :edit, {:id => scientific_name.to_param}
      assigns(:scientific_name).should eq(scientific_name)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new ScientificName" do
        expect {
          post :create, {:scientific_name => valid_attributes}
        }.to change(ScientificName, :count).by(1)
      end

      it "assigns a newly created scientific_name as @scientific_name" do
        post :create, {:scientific_name => valid_attributes}
        assigns(:scientific_name).should be_a(ScientificName)
        assigns(:scientific_name).should be_persisted
      end

      it "redirects to the created scientific_name" do
        post :create, {:scientific_name => valid_attributes}
        response.should redirect_to(ScientificName.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved scientific_name as @scientific_name" do
        # Trigger the behavior that occurs when invalid params are submitted
        ScientificName.any_instance.stub(:save).and_return(false)
        post :create, {:scientific_name => {}}
        assigns(:scientific_name).should be_a_new(ScientificName)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        ScientificName.any_instance.stub(:save).and_return(false)
        post :create, {:scientific_name => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested scientific_name" do
        scientific_name = ScientificName.create! valid_attributes
        # Assuming there are no other scientific_names in the database, this
        # specifies that the ScientificName created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        ScientificName.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => scientific_name.to_param, :scientific_name => {'these' => 'params'}}
      end

      it "assigns the requested scientific_name as @scientific_name" do
        scientific_name = ScientificName.create! valid_attributes
        put :update, {:id => scientific_name.to_param, :scientific_name => valid_attributes}
        assigns(:scientific_name).should eq(scientific_name)
      end

      it "redirects to the scientific_name" do
        scientific_name = ScientificName.create! valid_attributes
        put :update, {:id => scientific_name.to_param, :scientific_name => valid_attributes}
        response.should redirect_to(scientific_name)
      end
    end

    describe "with invalid params" do
      it "assigns the scientific_name as @scientific_name" do
        scientific_name = ScientificName.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        ScientificName.any_instance.stub(:save).and_return(false)
        put :update, {:id => scientific_name.to_param, :scientific_name => {}}
        assigns(:scientific_name).should eq(scientific_name)
      end

      it "re-renders the 'edit' template" do
        scientific_name = ScientificName.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        ScientificName.any_instance.stub(:save).and_return(false)
        put :update, {:id => scientific_name.to_param, :scientific_name => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested scientific_name" do
      scientific_name = ScientificName.create! valid_attributes
      expect {
        delete :destroy, {:id => scientific_name.to_param}
      }.to change(ScientificName, :count).by(-1)
    end

    it "redirects to the scientific_names list" do
      scientific_name = ScientificName.create! valid_attributes
      delete :destroy, {:id => scientific_name.to_param}
      response.should redirect_to(scientific_names_url)
    end
  end

end
