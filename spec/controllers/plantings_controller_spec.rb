# frozen_string_literal: true

require 'rails_helper'

describe PlantingsController, :search do
  login_member

  def valid_attributes
    {
      garden_id: create(:garden, owner: subject.current_member).id,
      crop_id:   create(:crop).id
    }
  end

  describe "GET index", :search do
    let!(:first_member)      { create(:member)                                                       }
    let!(:second_member)     { create(:member)                                                       }
    let!(:tomato)            { create(:tomato)                                                       }
    let!(:maize)             { create(:maize)                                                        }
    let!(:tomato_planting)   { create(:planting, crop: tomato, owner: first_member, created_at: 1.day.ago) }
    let!(:maize_planting)    { create(:planting, crop: maize, owner: second_member, created_at: 5.days.ago) }

    before do
      Planting.reindex
    end

    describe "assigns all plantings as @plantings" do
      before { get :index }

      it { expect(assigns(:plantings).size).to eq 2 }
      it { expect(assigns(:plantings)[0]['slug']).to eq tomato_planting.slug }
      it { expect(assigns(:plantings)[1]['slug']).to eq maize_planting.slug }
    end

    describe "picks up owner from params and shows owner's plantings only" do
      before { get :index, params: { member_slug: first_member.slug } }

      it { expect(assigns(:owner)).to eq first_member }
      it { expect(assigns(:plantings).size).to eq 1 }
      it { expect(assigns(:plantings).first['slug']).to eq tomato_planting.slug }
    end

    describe "picks up crop from params and shows the plantings for the crop only" do
      before { get :index, params: { crop_slug: maize.slug } }

      it { expect(assigns(:crop)).to eq maize }
      it { expect(assigns(:plantings).first['slug']).to eq maize_planting.slug }
    end
  end

  describe "GET new" do
    describe "picks up crop from params" do
      let(:crop) { create(:crop) }

      before { get :new, params: { crop_id: crop.id } }

      it { expect(assigns(:crop)).to eq(crop) }
    end

    describe "doesn't die if no crop specified" do
      before { get :new, params: {} }

      it { expect(assigns(:crop)).to be_a_new(Crop) }
    end

    describe "picks up member's garden from params" do
      let(:garden) { create(:garden, owner: member) }

      before { get :new, params: { garden_id: garden.id } }

      it { expect(assigns(:planting).garden).to eq(garden) }
    end

    describe "Doesn't display another member's garden on planting form" do
      let(:another_member) { create(:member) } # over-riding member from login_member()
      let(:garden) { create(:garden, owner: another_member) }

      before { get :new, params: { garden_id: garden.id } }

      it { expect(assigns(:planting).garden).not_to eq(garden) }
    end

    describe "Doesn't display un-approved crops on planting form" do
      let(:crop) { create(:crop, approval_status: 'pending') }
      let!(:garden) { create(:garden, owner: member) }

      before { get :new, params: { crop_id: crop.id } }

      it { expect(assigns(:crop)).not_to eq(crop) }
    end

    describe "Doesn't display rejected crops on planting form" do
      let(:crop) { create(:crop, approval_status: 'rejected', reason_for_rejection: 'nope') }
      let!(:garden) { create(:garden, owner: member) }

      before { get :new, params: { crop_id: crop.id } }

      it { expect(assigns(:crop)).not_to eq(crop) }
    end

    describe "doesn't die if no garden specified" do
      before { get :new, params: {} }

      it { expect(assigns(:planting)).to be_a_new(Planting) }
    end

    describe "sets the date of the planting to today" do
      before { get :new }

      it { expect(assigns(:planting).planted_at).to eq Time.zone.today }
    end

    context 'with parent seed' do
      let(:seed) { create(:seed, owner: member) }

      before { get :new, params: { seed_id: seed.to_param } }

      it { expect(assigns(:seed)).to eq(seed) }
    end
  end

  describe 'POST :create' do
    describe "sets the owner automatically" do
      before { post :create, params: { planting: valid_attributes } }

      it { expect(assigns(:planting).owner).to eq subject.current_member }
    end
  end

  describe 'GET :edit' do
    let(:my_planting) { create(:planting, owner: member) }
    let(:not_my_planting) { create(:planting) }

    context 'my planting' do
      before { get :edit, params: { slug: my_planting } }

      it { expect(assigns(:planting)).to eq my_planting }
    end

    context 'not my planting' do
      before { get :edit, params: { slug: not_my_planting } }

      it { expect(response).to redirect_to(root_path) }
    end
  end
end
