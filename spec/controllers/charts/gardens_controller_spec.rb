require 'rails_helper'

describe Charts::GardensController do
  include Devise::Test::ControllerHelpers
  let(:valid_params) { { name: 'My second Garden' } }

  let(:garden) { FactoryBot.create :garden }
  context "when not signed in" do
    describe 'GET timeline' do
      before { get :timeline, garden_id: garden.to_param }
      it { expect(response).to be_success }
    end
  end
  context "when signed in" do
    before(:each) { sign_in member }

    let!(:member) { FactoryBot.create(:member) }
    describe 'GET timeline' do
      before { get :timeline, garden_id: garden.to_param }
      it { expect(response).to be_success }
    end
  end
end
