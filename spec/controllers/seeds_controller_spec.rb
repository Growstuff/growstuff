# frozen_string_literal: true

require 'rails_helper'

describe SeedsController, :search do
  let(:owner) { FactoryBot.create(:member) }

  describe "GET index" do
    describe "picks up owner from params" do
      before do
        Seed.reindex
        get :index, params: { member_slug: owner.slug }
      end

      it { expect(assigns(:owner)).to eq(owner) }
    end
  end

  describe 'GET new' do
    before { sign_in owner }

    it { expect(response).to be_successful }

    context 'no parent planting' do
      before { get :new }
    end

    context 'with parent planting' do
      let!(:planting) { FactoryBot.create :planting, owner: owner }

      before do
        Seed.reindex
        get :new, params: { planting_slug: planting.to_param }
      end

      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
