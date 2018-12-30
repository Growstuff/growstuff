require 'rails_helper'

describe SeedsController do
  let(:owner) { FactoryBot.create(:member) }
  let(:crop) { FactoryBot.create :crop }

  let!(:seed) { FactoryBot.create :seed, description: 'someone elses seeds' }
  let!(:seed_of_crop) { FactoryBot.create :seed, crop: crop, description: 'seeds of same crop' }
  let!(:seed_of_owner) { FactoryBot.create :seed, owner: owner, description: 'seeds of owner' }
  let!(:seed_of_crop_and_owner) do
    FactoryBot.create :seed,
      crop: crop, owner: owner, description: 'seeds of same crop and owner'
  end

  describe "GET index" do
    context 'default' do
      before { get :index, params: {} }
      it { expect(assigns(:seeds).size).to eq 4 }
      it { expect(assigns(:seeds)).to include seed }
      it { expect(assigns(:seeds)).to include seed_of_crop }
      it { expect(assigns(:seeds)).to include seed_of_owner }
      it { expect(assigns(:seeds)).to include seed_of_crop_and_owner }
    end

    context 'with owner' do
      before { get :index, params: { owner: owner.slug } }

      it "picks up owner from params" do
        expect(assigns(:owner)).to eq(owner)
      end
      it { expect(assigns(:seeds).size).to eq 2 }
      it { expect(assigns(:seeds)).to include seed_of_owner }
      it { expect(assigns(:seeds)).to include seed_of_crop_and_owner }

      # but not these
      it { expect(assigns(:seeds)).not_to include seed }
      it { expect(assigns(:seeds)).not_to include seed_of_crop }
    end

    context 'with crop' do
      before { get :index, params: { crop: crop.slug } }

      it "picks up crop from params" do
        expect(assigns(:crop)).to eq(crop)
      end
      it { expect(assigns(:seeds).size).to eq 2 }
      it { expect(assigns(:seeds)).to include seed_of_crop }
      it { expect(assigns(:seeds)).to include seed_of_crop_and_owner }

      # but not these
      it { expect(assigns(:seeds)).not_to include seed }
      it { expect(assigns(:seeds)).not_to include seed_of_owner }
    end
  end

  describe 'GET new' do
    before { sign_in owner }

    it { expect(response).to be_success }

    context 'for a planting with no parent' do
      context 'default' do
        before { get :new }
        it { expect(assigns(:seed)).to be_a Seed }
      end

      context 'with planting' do
        let(:planting) { FactoryBot.create :planting }
        before { get :new, params: { planting_id: planting.slug } }
        it { expect(assigns(:planting)).to eq planting }
      end

      context 'with crop' do
        let(:crop) { FactoryBot.create :crop }
        before { get :new, params: { crop_id: crop.id } }
        it { expect(assigns(:crop)).to eq crop }
      end
    end

    context 'with parent planting' do
      let(:planting) { FactoryBot.create :planting, owner: owner }
      before { get :new, params: { planting_id: planting.to_param } }
      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
