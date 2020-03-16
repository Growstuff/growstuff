# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GardenTypesController, type: :controller do
  include Devise::Test::ControllerHelpers
  let(:valid_params) { { name: 'My second GardenType' } }
  let(:garden_type)  { FactoryBot.create :garden_type   }

  context "when not signed in" do
    describe 'GET new' do
      before { get :new, params: { id: garden_type.to_param } }

      it { expect(response).to redirect_to(root_path) }
    end

    describe 'PUT create' do
      before { put :create, params: { garden_type: valid_params } }

      it { expect(response).to redirect_to(root_path) }
    end

    describe 'changing existing records' do
      before do
        allow(GardenType).to receive(:find).and_return(:garden_type)
        expect(garden_type).not_to receive(:save)
        expect(garden_type).not_to receive(:save!)
        expect(garden_type).not_to receive(:update)
        expect(garden_type).not_to receive(:update!)
        expect(garden_type).not_to receive(:destroy)
      end

      describe 'GET edit' do
        before { get :edit, params: { id: garden_type.to_param } }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'POST update' do
        before { post :update, params: { id: garden_type.to_param, garden_type: valid_params } }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'DELETE' do
        before { delete :destroy, params: { id: garden_type.to_param, params: { garden_type: valid_params } } }

        it { expect(response).to redirect_to(root_path) }
      end
    end
  end

  context "when signed in as a member" do
    before { sign_in member }

    let!(:member) { FactoryBot.create(:member) }

    describe "for any garden_type" do
      let(:any_garden_type) { double('garden_type') }

      before do
        expect(GardenType).to receive(:find).and_return(:any_garden_type)
        expect(any_garden_type).not_to receive(:save)
        expect(any_garden_type).not_to receive(:save!)
        expect(any_garden_type).not_to receive(:update)
        expect(any_garden_type).not_to receive(:update!)
        expect(any_garden_type).not_to receive(:destroy)
      end

      describe 'GET edit' do
        before { get :edit, params: { id: any_garden_type.to_param } }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'POST update' do
        before { post :update, params: { id: any_garden_type.to_param, garden_type: valid_params } }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'DELETE' do
        before { delete :destroy, params: { id: any_garden_type.to_param, params: { garden_type: valid_params } } }

        it { expect(response).to redirect_to(root_path) }
      end
    end
  end
end
