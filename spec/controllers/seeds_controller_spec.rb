require 'rails_helper'

describe SeedsController do
  describe "GET index" do
    let(:owner) { FactoryBot.create(:member) }
    describe "picks up owner from params" do
      before { get :index, params: { owner: owner.slug } }
      it { expect(assigns(:owner)).to eq(owner) }
    end
  end
end
