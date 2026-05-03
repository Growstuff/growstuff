# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GardensController do
  include Devise::Test::ControllerHelpers

  let(:valid_params) { { name: 'My second Garden' } }

  let(:garden) { create(:garden) }

  context "when not signed in" do
    describe 'GET new' do
      before { get :new, params: { slug: garden.to_param } }

      it { expect(response).to redirect_to(new_member_session_path) }
    end

    describe 'PUT create' do
      before { put :create, params: { garden: valid_params } }

      it { expect(response).to redirect_to(new_member_session_path) }
    end

    describe 'changing existing records' do
      before do
        allow(Garden).to receive(:find).and_return(:garden)
      end

      describe 'GET edit' do
        it "redirects to login" do
          expect(garden).not_to receive(:save)
          expect(garden).not_to receive(:save!)
          expect(garden).not_to receive(:update)
          expect(garden).not_to receive(:update!)
          expect(garden).not_to receive(:destroy)
          get :edit, params: { slug: garden.to_param }
          expect(response).to redirect_to(new_member_session_path)
        end
      end

      describe 'POST update' do
        it "redirects to login" do
          expect(garden).not_to receive(:save)
          expect(garden).not_to receive(:save!)
          expect(garden).not_to receive(:update)
          expect(garden).not_to receive(:update!)
          expect(garden).not_to receive(:destroy)
          post :update, params: { slug: garden.to_param, garden: valid_params }
          expect(response).to redirect_to(new_member_session_path)
        end
      end

      describe 'DELETE' do
        it "redirects to login" do
          expect(garden).not_to receive(:save)
          expect(garden).not_to receive(:save!)
          expect(garden).not_to receive(:update)
          expect(garden).not_to receive(:update!)
          expect(garden).not_to receive(:destroy)
          delete :destroy, params: { slug: garden.to_param, params: { garden: valid_params } }
          expect(response).to redirect_to(new_member_session_path)
        end
      end
    end
  end

  context "when signed in" do
    before { sign_in member }

    let!(:member) { create(:member) }

    describe "for another member's garden" do
      let(:not_my_garden) { double('garden') }

      before do
        allow(Garden).to receive(:find).and_return(:not_my_garden)
      end

      describe 'GET edit' do
        it "redirects to root" do
          expect(not_my_garden).not_to receive(:save)
          expect(not_my_garden).not_to receive(:save!)
          expect(not_my_garden).not_to receive(:update)
          expect(not_my_garden).not_to receive(:update!)
          expect(not_my_garden).not_to receive(:destroy)
          get :edit, params: { slug: not_my_garden.to_param }
          expect(response).to redirect_to(root_path)
        end
      end

      describe 'POST update' do
        it "redirects to root" do
          expect(not_my_garden).not_to receive(:save)
          expect(not_my_garden).not_to receive(:save!)
          expect(not_my_garden).not_to receive(:update)
          expect(not_my_garden).not_to receive(:update!)
          expect(not_my_garden).not_to receive(:destroy)
          post :update, params: { slug: not_my_garden.to_param, garden: valid_params }
          expect(response).to redirect_to(root_path)
        end
      end

      describe 'DELETE' do
        it "redirects to root" do
          expect(not_my_garden).not_to receive(:save)
          expect(not_my_garden).not_to receive(:save!)
          expect(not_my_garden).not_to receive(:update)
          expect(not_my_garden).not_to receive(:update!)
          expect(not_my_garden).not_to receive(:destroy)
          delete :destroy, params: { slug: not_my_garden.to_param, params: { garden: valid_params } }
          expect(response).to redirect_to(root_path)
        end
      end
    end
  end
end
