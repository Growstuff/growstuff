require 'rails_helper'

describe Charts::CropsController do
  describe 'GET charts' do
    let(:crop) { FactoryBot.create :crop }
    describe 'sunniness' do
      before { get :sunniness, params: { crop_id: crop.to_param } }
      it { expect(response).to be_success }
    end
    describe 'planted_from' do
      before { get :planted_from, params: { crop_id: crop.to_param } }
      it { expect(response).to be_success }
    end
    describe 'harvested_for' do
      before { get :harvested_for, params: { crop_id: crop.to_param } }
      it { expect(response).to be_success }
    end
  end
end
