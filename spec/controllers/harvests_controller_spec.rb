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

describe HarvestsController do
  login_member

  def valid_attributes
    {
      owner_id: subject.current_member.id,
      crop_id: FactoryBot.create(:crop).id,
      plant_part_id: FactoryBot.create(:plant_part).id
    }
  end

  describe "GET index" do
    before do
      @member1 = FactoryBot.create(:member)
      @member2 = FactoryBot.create(:member)
      @tomato = FactoryBot.create(:tomato)
      @maize = FactoryBot.create(:maize)
      @harvest1 = FactoryBot.create(:harvest, owner_id: @member1.id, crop_id: @tomato.id)
      @harvest2 = FactoryBot.create(:harvest, owner_id: @member2.id, crop_id: @maize.id)
    end

    it "assigns all harvests as @harvests" do
      get :index, {}
      assigns(:harvests).should =~ [@harvest1, @harvest2]
    end

    it "picks up owner from params and shows owner's harvests only" do
      get :index, owner: @member1.slug
      assigns(:owner).should eq @member1
      assigns(:harvests).should eq [@harvest1]
    end

    it "picks up crop from params and shows the harvests for the crop only" do
      get :index, crop: @maize.name
      assigns(:crop).should eq @maize
      assigns(:harvests).should eq [@harvest2]
    end

    it "generates a csv" do
      get :index, format: "csv"
      response.status.should eq 200
    end
  end

  describe "GET show" do
    it "assigns the requested harvest as @harvest" do
      harvest = Harvest.create! valid_attributes
      get :show, id: harvest.to_param
      assigns(:harvest).should eq(harvest)
    end
  end

  describe "GET new" do
    it "assigns a new harvest as @harvest" do
      get :new, {}
      assigns(:harvest).should be_a_new(Harvest)
    end

    it "sets the date of the harvest to today" do
      get :new, {}
      assigns(:harvest).harvested_at.should == Time.zone.today
    end
  end

  describe "GET edit" do
    it "assigns the requested harvest as @harvest" do
      harvest = Harvest.create! valid_attributes
      get :edit, id: harvest.to_param
      assigns(:harvest).should eq(harvest)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Harvest" do
        expect do
          post :create, harvest: valid_attributes
        end.to change(Harvest, :count).by(1)
      end

      it "assigns a newly created harvest as @harvest" do
        post :create, harvest: valid_attributes
        assigns(:harvest).should be_a(Harvest)
        assigns(:harvest).should be_persisted
      end

      it "redirects to the created harvest" do
        post :create, harvest: valid_attributes
        response.should redirect_to(Harvest.last)
      end

      it "links to planting" do
        planting = FactoryBot.create(:planting, owner_id: member.id)
        post :create, harvest: valid_attributes.merge(planting_id: planting.id)
        expect(Harvest.last.planting.id).to eq(planting.id)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved harvest as @harvest" do
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        post :create, harvest: { "crop_id" => "invalid value" }
        assigns(:harvest).should be_a_new(Harvest)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        post :create, harvest: { "crop_id" => "invalid value" }
        response.should render_template("new")
      end
    end

    describe "not my planting" do
      let(:not_my_planting) { FactoryBot.create(:planting) }
      let(:harvest) { FactoryBot.create(:harvest) }
      it "does not save planting_id" do
        allow(Harvest).to receive(:new).and_return(harvest)
        post :create, harvest: valid_attributes.merge(planting_id: not_my_planting.id)
        expect(harvest.planting_id).to eq(nil)
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested harvest" do
        harvest = Harvest.create! valid_attributes
        # Assuming there are no other harvests in the database, this
        # specifies that the Harvest created on the previous line
        # receives the :update message with whatever params are
        # submitted in the request.
        Harvest.any_instance.should_receive(:update).with("crop_id" => "1", "owner_id": member.id)
        put :update, id: harvest.to_param, harvest: { "crop_id" => "1" }
      end

      it "assigns the requested harvest as @harvest" do
        harvest = Harvest.create! valid_attributes
        put :update, id: harvest.to_param, harvest: valid_attributes
        assigns(:harvest).should eq(harvest)
      end

      it "redirects to the harvest" do
        harvest = Harvest.create! valid_attributes
        put :update, id: harvest.to_param, harvest: valid_attributes
        response.should redirect_to(harvest)
      end
    end

    describe "with invalid params" do
      it "assigns the harvest as @harvest" do
        harvest = Harvest.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        put :update, id: harvest.to_param, harvest: { "crop_id" => "invalid value" }
        assigns(:harvest).should eq(harvest)
      end

      it "re-renders the 'edit' template" do
        harvest = Harvest.create! valid_attributes
        put :update, id: harvest.to_param, harvest: { "crop_id" => "invalid value" }
        response.should render_template("edit")
      end
    end

    describe "not my planting" do
      let(:not_my_planting) { FactoryBot.create(:planting) }
      let(:harvest) { FactoryBot.create(:harvest) }
      it "does not save planting_id" do
        put :update, id: harvest.to_param,
                     harvest: valid_attributes.merge(planting_id: not_my_planting.id)
        expect(harvest.planting_id).to eq(nil)
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested harvest" do
      harvest = Harvest.create! valid_attributes
      expect do
        delete :destroy, id: harvest.to_param
      end.to change(Harvest, :count).by(-1)
    end

    it "redirects to the harvests list" do
      harvest = Harvest.create! valid_attributes
      delete :destroy, id: harvest.to_param
      response.should redirect_to(harvests_url)
    end
  end
end
