require 'rails_helper'

describe SeedsController do
  let(:owner) { FactoryBot.create(:member) }

  describe 'GET index' do
    let(:owner) { FactoryBot.create(:member) }

    describe 'picks up owner from params' do
      before { get :index, params: { member_slug: owner.slug } }

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
      let(:planting) { FactoryBot.create :planting, owner: owner }

      before { get :new, params: { planting_id: planting.to_param } }

      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
