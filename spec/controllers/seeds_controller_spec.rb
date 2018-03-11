require 'rails_helper'

describe SeedsController do
  let(:owner) { FactoryBot.create(:member) }

  describe "GET index" do
    before { get :index, owner: owner.slug }
    it "picks up owner from params" do
      assigns(:owner).should eq(owner)
    end
  end

  describe 'GET new' do
    before { sign_in owner }

    it { expect(response).to be_success }

    context 'no parent planting' do
      before { get :new }
    end

    context 'with parent planting' do
      let(:planting) { FactoryBot.create :planting, owner: owner }
      before { get :new, planting_id: planting.to_param }
      it { expect(assigns(:planting)).to eq(planting) }
    end
  end
end
