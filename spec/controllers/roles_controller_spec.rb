require 'rails_helper'

describe RolesController do
  def valid_attributes
    { "name" => "MyString" }
  end

  login_member(:admin_member)

  let!(:role) { FactoryBot.create :role, name: 'zebra' }

  # note that admin role exists because of login_admin_member
  let(:admin_role) { Role.find_by(name: 'admin') }

  describe "GET index" do
    before { get :index }
    it { expect(assigns(:roles)).to eq([admin_role, role]) }
  end

  describe "GET edit" do
    before { get :edit, params: { id: role.id } }
    it { expect(assigns(:role)).to eq role }
  end

  describe "GET show" do
    before { get :show, params: { id: role.id } }
    it { expect(assigns(:role)).to eq role }
  end

  describe 'POST create' do
    subject { post :create, params: { role: { name: 'chef' } } }
    it { expect { subject }.to change { Role.count }.by(1) }
    it { expect(subject.request.flash[:notice]).to_not be_nil }
  end

  describe 'DELETE destroy' do
    subject { delete :destroy, params: { id: role.id } }
    it { expect { subject }.to change { Role.count }.by(-1) }
    it { expect(subject.request.flash[:notice]).to_not be_nil }
  end
end
