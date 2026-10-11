# frozen_string_literal: true

require 'rails_helper'

describe SeedsController do
  let(:owner) { create(:member) }

  describe "GET index" do
    describe "picks up owner from params" do
      before do
        get :index, params: { member_slug: owner.slug }
      end

      it { expect(assigns(:owner)).to eq(owner) }
    end

    describe "sorting by nearness on a crop" do
      let(:crop) { create(:crop) }
      let(:viewer) { create(:london_member) }
      let!(:far_seed) { create(:seed, crop:, owner: create(:south_pole_member)) }
      let!(:unlocated_seed) { create(:seed, crop:, owner: create(:member)) }
      let!(:near_seed) { create(:seed, crop:, owner: create(:london_member)) }

      it 'lists nearest first when signed in with a location' do
        sign_in viewer
        get :index, params: { crop_slug: crop.slug }
        expect(assigns(:seeds).to_a).to eq([near_seed, far_seed, unlocated_seed])
      end

      it 'does not sort by distance when signed out' do
        get :index, params: { crop_slug: crop.slug }
        expect(assigns(:sort_by_distance)).to be false
      end
    end
  end

  describe 'GET new' do
    before { sign_in owner }

    it { expect(response).to be_successful }

    context 'with parent planting' do
      let!(:planting) { create(:planting, owner:) }

      before do
        get :new, params: { planting_slug: planting.to_param }
      end

      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
