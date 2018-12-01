require 'rails_helper'

RSpec.describe ContainersController, type: :controller do
  include Devise::Test::ControllerHelpers
  let(:valid_params) { { description: 'My second Container' } }
  let(:container) { FactoryBot.create :container }

  let(:member) { FactoryBot.create(:member) }
  let(:admin_member) { FactoryBot.create(:admin) }

  context "when not signed in" do
    describe 'GET new' do
      before { get :new, id: container.to_param }

      it { expect(response).to redirect_to(root_path) }
    end

    describe 'PUT create' do
      before { put :create, container: valid_params }

      it { expect(response).to redirect_to(root_path) }
    end

    describe 'changing existing records' do
      before do
        allow(Container).to receive(:find).and_return(:container)
        expect(container).not_to receive(:save)
        expect(container).not_to receive(:save!)
        expect(container).not_to receive(:update)
        expect(container).not_to receive(:update!)
        expect(container).not_to receive(:destroy)
      end

      describe 'GET edit' do
        before { get :edit, id: container.to_param }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'POST update' do
        before { post :update, id: container.to_param, container: valid_params }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'DELETE' do
        before { delete :destroy, id: container.to_param, params: { container: valid_params } }

        it { expect(response).to redirect_to(root_path) }
      end
    end
  end

  context "when signed in as a member" do
    before(:each) { sign_in member }

    let!(:member) { FactoryBot.create(:member) }

    describe "for any container" do
      let(:any_container) { double('container') }

      before do
        expect(Container).to receive(:find).and_return(:any_container)
        expect(any_container).not_to receive(:save)
        expect(any_container).not_to receive(:save!)
        expect(any_container).not_to receive(:update)
        expect(any_container).not_to receive(:update!)
        expect(any_container).not_to receive(:destroy)
      end

      describe 'GET edit' do
        before { get :edit, id: any_container.to_param }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'POST update' do
        before { post :update, id: any_container.to_param, container: valid_params }

        it { expect(response).to redirect_to(root_path) }
      end

      describe 'DELETE' do
        before { delete :destroy, id: any_container.to_param, params: { container: valid_params } }

        it { expect(response).to redirect_to(root_path) }
      end
    end
  end
end
