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
