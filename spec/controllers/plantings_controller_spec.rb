require 'rails_helper'

describe PlantingsController do
  login_member

  def valid_attributes
    {
      garden_id: FactoryBot.create(:garden, owner: subject.current_member).id,
      crop_id: FactoryBot.create(:crop).id
    }
  end

  describe "GET index" do
    let!(:member1) { FactoryBot.create(:member) }
    let!(:member2) { FactoryBot.create(:member) }
    let!(:tomato) { FactoryBot.create(:tomato) }
    let!(:maize) { FactoryBot.create(:maize) }
    let!(:planting1) { FactoryBot.create :planting, crop: tomato, owner: member1, created_at: 1.day.ago }
    let!(:planting2) { FactoryBot.create :planting, crop: maize, owner: member2, created_at: 5.days.ago }

    describe "assigns all plantings as @plantings" do
      before { get :index, {} }
      it { expect(assigns(:plantings)).to match [planting1, planting2] }
    end

    describe "picks up owner from params and shows owner's plantings only" do
      before { get :index, owner: member1.slug }
      it { expect(assigns(:owner)).to eq member1 }
      it { expect(assigns(:plantings)).to eq [planting1] }
    end

    describe "picks up crop from params and shows the plantings for the crop only" do
      before { get :index, crop: maize.name }
      it { expect(assigns(:crop)).to eq maize }
      it { expect(assigns(:plantings)).to eq [planting2] }
    end
  end

  describe "GET new" do
    describe "picks up crop from params" do
      let(:crop) { FactoryBot.create(:crop) }

      before { get :new, crop_id: crop.id }
      it { expect(assigns(:crop)).to eq(crop) }
    end

    describe "doesn't die if no crop specified" do
      before { get :new, {} }
      it { expect(assigns(:crop)).to be_a_new(Crop) }
    end

    describe "picks up member's garden from params" do
      let(:garden) { FactoryBot.create(:garden, owner: member) }

      before { get :new, garden_id: garden.id }
      it { expect(assigns(:garden)).to eq(garden) }
    end

    describe "Doesn't display another member's garden on planting form" do
      let(:another_member) { FactoryBot.create(:member) } # over-riding member from login_member()
      let(:garden) { FactoryBot.create(:garden, owner: another_member) }

      before { get :new, garden_id: garden.id }
      it { expect(assigns(:garden)).not_to eq(garden) }
    end

    describe "Doesn't display un-approved crops on planting form" do
      let(:crop) { FactoryBot.create(:crop, approval_status: 'pending') }
      let!(:garden) { FactoryBot.create(:garden, owner: member) }

      before { get :new, crop_id: crop.id }
      it { expect(assigns(:crop)).not_to eq(crop) }
    end

    describe "Doesn't display rejected crops on planting form" do
      let(:crop) { FactoryBot.create(:crop, approval_status: 'rejected', reason_for_rejection: 'nope') }
      let!(:garden) { FactoryBot.create(:garden, owner: member) }

      before { get :new, crop_id: crop.id }
      it { expect(assigns(:crop)).not_to eq(crop) }
    end

    describe "doesn't die if no garden specified" do
      before { get :new, {} }
      it { expect(assigns(:garden)).to be_a_new(Garden) }
    end

    describe "sets the date of the planting to today" do
      before { get :new, {} }
      it { expect(assigns(:planting).planted_at).to eq Time.zone.today }
    end

    context 'with parent seed' do
      let(:seed) { FactoryBot.create :seed, owner: member }
      before { get :new, seed_id: seed.to_param }
      it { expect(assigns(:seed)).to eq(seed) }
    end
  end

  describe 'POST :create' do
    describe "sets the owner automatically" do
      before { post :create, planting: valid_attributes }
      it { expect(assigns(:planting).owner).to eq subject.current_member }
    end
  end
end
