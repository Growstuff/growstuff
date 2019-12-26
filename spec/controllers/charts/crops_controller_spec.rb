# frozen_string_literal: true

require 'rails_helper'

describe Charts::CropsController do
  describe 'GET charts' do
    let(:crop) { FactoryBot.create :crop }

    describe 'sunniness' do
      before { get :sunniness, params: { crop_slug: crop.to_param } }

      it { expect(response).to be_successful }
    end

    describe 'planted_from' do
      before { get :planted_from, params: { crop_slug: crop.to_param } }

      it { expect(response).to be_successful }
    end

    describe 'harvested_for' do
      before { get :harvested_for, params: { crop_slug: crop.to_param } }

      it { expect(response).to be_successful }
    end
  end
end
