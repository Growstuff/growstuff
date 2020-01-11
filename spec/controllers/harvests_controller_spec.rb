# frozen_string_literal: true

require 'rails_helper'

describe HarvestsController, :search do
  login_member

  def valid_attributes
    {
      owner_id:      subject.current_member.id,
      crop_id:       FactoryBot.create(:crop).id,
      plant_part_id: FactoryBot.create(:plant_part).id,
      harvested_at:  '2017-01-01'
    }
  end

  describe "GET index" do
    let!(:member1)  { FactoryBot.create(:member)                                            }
    let(:member2)   { FactoryBot.create(:member)                                            }
    let(:tomato)    { FactoryBot.create(:tomato)                                            }
    let(:maize)     { FactoryBot.create(:maize)                                             }
    let!(:harvest1) { FactoryBot.create(:harvest, owner_id: member1.id, crop_id: tomato.id) }
    let!(:harvest2) { FactoryBot.create(:harvest, owner_id: member2.id, crop_id: maize.id)  }

    before { Harvest.reindex }

    describe "assigns all harvests as @harvests" do
      before { get :index, params: {} }

      it { expect(assigns(:harvests).size).to eq 2 }
      it { expect(assigns(:harvests)[0].slug).to eq harvest1.slug }
      it { expect(assigns(:harvests)[1].slug).to eq harvest2.slug }
    end

    describe "picks up owner from params and shows owner's harvests only" do
      before { get :index, params: { member_slug: member1.slug } }

      it { expect(assigns(:owner)).to eq member1 }
      it { expect(assigns(:harvests).size).to eq 1 }
      it { expect(assigns(:harvests)[0].slug).to eq harvest1.slug }
    end

    describe "picks up crop from params and shows the harvests for the crop only" do
      before { get :index, params: { crop_slug: maize.name } }

      it { expect(assigns(:crop)).to eq maize }
      it { expect(assigns(:harvests).size).to eq 1 }
      it { expect(assigns(:harvests)[0].slug).to eq harvest2.slug }
    end

    describe "generates a csv" do
      before { get :index, format: "csv" }

      it { expect(response.status).to eq 200 }
    end
  end

  describe "GET show" do
    let(:harvest) { Harvest.create! valid_attributes }

    describe "assigns the requested harvest as @harvest" do
      before { get :show, params: { slug: harvest.to_param } }

      it { expect(assigns(:harvest)).to eq(harvest) }
    end
  end

  describe "GET new" do
    before { get :new, params: {} }

    describe "assigns a new harvest as @harvest" do
      it { expect(assigns(:harvest)).to be_a_new(Harvest) }
    end

    describe "sets the date of the harvest to today" do
      it { expect(assigns(:harvest).harvested_at).to eq(Time.zone.today) }
    end
  end

  describe "GET edit" do
    let(:harvest) { Harvest.create! valid_attributes }

    describe "assigns the requested harvest as @harvest" do
      before { get :edit, params: { slug: harvest.to_param } }

      it { expect(assigns(:harvest)).to eq(harvest) }
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Harvest" do
        expect do
          post :create, params: { harvest: valid_attributes }
        end.to change(Harvest, :count).by(1)
      end

      describe "assigns a newly created harvest as @harvest" do
        before { post :create, params: { harvest: valid_attributes } }

        it { expect(assigns(:harvest)).to be_a(Harvest) }
        it { expect(assigns(:harvest)).to be_persisted }
      end

      describe "redirects to the created harvest" do
        before { post :create, params: { harvest: valid_attributes } }

        it { expect(response).to redirect_to(Harvest.last) }
      end

      describe "links to planting" do
        let(:planting) { FactoryBot.create(:planting, owner_id: member.id, garden: member.gardens.first) }

        before { post :create, params: { harvest: valid_attributes.merge(planting_id: planting.id) } }

        it { expect(Harvest.last.planting.id).to eq(planting.id) }
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved harvest as @harvest" do
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        post :create, params: { harvest: { "crop_id" => "invalid value" } }
        expect(assigns(:harvest)).to be_a_new(Harvest)
      end

      describe "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        before { post :create, params: { harvest: { "crop_id" => "invalid value" } } }

        it { expect(response).to render_template("new") }
      end
    end

    describe "not my planting" do
      let(:not_my_planting) { FactoryBot.create(:planting) }
      let(:harvest)         { FactoryBot.create(:harvest)  }

      describe "does not save planting_id" do
        before do
          allow(Harvest).to receive(:new).and_return(harvest)
          post :create, params: { harvest: valid_attributes.merge(planting_id: not_my_planting.id) }
        end

        it { expect(harvest.planting_id).not_to eq(not_my_planting.id) }
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      let(:harvest) { Harvest.create! valid_attributes }

      it "updates the requested harvest" do
        new_crop = FactoryBot.create :crop
        expect do
          put :update, params: { slug: harvest.to_param, harvest: { crop_id: new_crop.id } }
          harvest.reload
        end.to change(harvest, :crop_id).to(new_crop.id)
      end

      describe "assigns the requested harvest as @harvest" do
        before { put :update, params: { slug: harvest.to_param, harvest: valid_attributes } }

        it { expect(assigns(:harvest)).to eq(harvest) }
      end

      describe "redirects to the harvest" do
        before { put :update, params: { slug: harvest.to_param, harvest: valid_attributes } }

        it { expect(response).to redirect_to(harvest) }
      end
    end

    describe "with invalid params" do
      it "assigns the harvest as @harvest" do
        harvest = Harvest.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Harvest.any_instance.stub(:save).and_return(false)
        put :update, params: { slug: harvest.to_param, harvest: { "crop_id" => "invalid value" } }
        expect(assigns(:harvest)).to eq(harvest)
      end

      it "re-renders the 'edit' template" do
        harvest = Harvest.create! valid_attributes
        put :update, params: { slug: harvest.to_param, harvest: { "crop_id" => "invalid value" } }
        expect(response).to render_template("edit")
      end
    end

    describe "not my planting" do
      let(:not_my_planting) { FactoryBot.create(:planting) }
      let(:harvest)         { FactoryBot.create(:harvest)  }

      describe "does not save planting_id" do
        before do
          put :update, params: {
            slug:    harvest.to_param,
            harvest: valid_attributes.merge(planting_id: not_my_planting.id)
          }
        end

        it { expect(harvest.planting_id).to eq(nil) }
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested harvest" do
      harvest = Harvest.create! valid_attributes
      expect do
        delete :destroy, params: { slug: harvest.to_param }
      end.to change(Harvest, :count).by(-1)
    end

    it "redirects to the harvests list" do
      harvest = Harvest.create! valid_attributes
      delete :destroy, params: { slug: harvest.to_param }
      expect(response).to redirect_to(harvests_url)
    end
  end
end
