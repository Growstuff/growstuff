# frozen_string_literal: true

require 'rails_helper'

describe Admin::RolesController do
  let(:valid_attributes) { { "name" => "MyString" } }
  let!(:role) { Role.create! valid_attributes }

  context 'as member' do
    login_member(:member)

    describe "GET index" do
      before { get :index }
      it { expect(assigns(:roles)).to eq(nil) }
    end

    describe "GET new" do
      before { get :new }
      it { expect(assigns(:role)).to eq nil }
    end

    describe "create" do
      it do
        expect { post :create, params: { role: { name: ' new role' } } }.not_to change(Role, :count)
      end
    end

    describe "GET edit" do
      before { get :edit, params: { id: role.to_param } }
      it { expect(assigns(:role)).to eq(nil) }
    end

    describe "update" do
      before { patch :update, params: { id: role.id, role: { name: 'updated role' } } }
      it { expect(Role.first.name).to eq 'MyString' }
    end
  end

  context 'as admin' do
    login_member(:admin_member)

    describe "GET index" do
      before { get :index }
      it { expect(assigns(:roles)).to eq([Role.find_by(name: 'admin'), role]) }
    end

    describe "GET new" do
      before { get :new }
      it { expect(assigns(:role)).to be_a(Role) }
    end

    describe "create" do
      it do
        expect { post :create, params: { role: { name: ' new role' } } }.to change(Role, :count).by(1)
        # doesn't allow duplicates
        expect { post :create, params: { role: { name: ' new role' } } }.not_to change(Role, :count)
      end
    end

    describe "GET edit" do
      before { get :edit, params: { id: role.to_param } }
      it { expect(assigns(:role)).to eq(role) }
    end

    describe "update" do
      before { patch :update, params: { id: role.id, role: { name: 'updated role' } } }
      it { expect(Role.first.name).to eq 'updated role' }
    end
  end
end
