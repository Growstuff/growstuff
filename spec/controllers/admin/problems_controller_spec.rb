# frozen_string_literal: true

require 'rails_helper'

describe Admin::ProblemsController, type: :controller do
  let(:valid_attributes) { { "title" => "Tomato Blight", "problem_type" => "Disease", "description" => "Fungal disease" } }
  let!(:problem) { Problem.create! valid_attributes }

  before do
    Flipper.enable(:problems)
  end

  context 'when feature flag is disabled' do
    login_member(:admin_member)

    before do
      Flipper.disable(:problems)
      get :index
    end

    it 'is not found' do
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'as anonymous user' do
    describe "GET index" do
      it "redirects to login" do
        get :index
        expect(response).to redirect_to(new_member_session_path)
      end
    end
  end

  context 'as regular member' do
    login_member(:member)

    describe "GET index" do
      before { get :index }

      it { expect(assigns(:problems)).to be_nil }
    end

    describe "GET new" do
      before { get :new }

      it { expect(assigns(:problem)).to be_nil }
    end

    describe "POST create" do
      it "does not create a problem" do
        expect {
          post :create, params: { problem: { title: 'New Problem', problem_type: 'Disease' } }
        }.not_to change(Problem, :count)
      end
    end

    describe "DELETE destroy" do
      it "does not destroy the problem" do
        expect {
          delete :destroy, params: { id: problem.id }
        }.not_to change(Problem, :count)
      end
    end
  end

  context 'as admin' do
    login_member(:admin_member)

    describe "GET index" do
      before { get :index }

      it { expect(assigns(:problems)).to eq([problem]) }
    end

    describe "GET show" do
      before { get :show, params: { id: problem.id } }

      it { expect(assigns(:problem)).to eq(problem) }
    end

    describe "GET new" do
      before { get :new }

      it { expect(assigns(:problem)).to be_a_new(Problem) }
    end

    describe "POST create" do
      it "creates a new problem with scientific and alternate names" do
        params = {
          problem: {
            title: 'Aphids',
            problem_type: 'Pest',
            description: 'Small sap-sucking insects',
            scientific_names_attributes: [
              { name: 'Aphidoidea', gbif_key: '6085', wikidata_id: 'Q208552' }
            ],
            alternate_names_attributes: [
              { name: 'Greenfly', language: 'EN' }
            ]
          }
        }

        expect { post :create, params: params }.to change(Problem, :count).by(1)
        created = Problem.find_by(title: 'Aphids')
        expect(created.problem_type).to eq('Pest')
        expect(created.scientific_names.first.name).to eq('Aphidoidea')
        expect(created.scientific_names.first.gbif_key).to eq(6085)
        expect(created.scientific_names.first.wikidata_id).to eq('Q208552')
        expect(created.alternate_names.first.name).to eq('Greenfly')
      end
    end

    describe "GET edit" do
      before { get :edit, params: { id: problem.id } }

      it { expect(assigns(:problem)).to eq(problem) }
    end

    describe "PATCH update" do
      it "updates the problem" do
        patch :update, params: { id: problem.id, problem: { title: 'Updated Title' } }
        expect(problem.reload.title).to eq('Updated Title')
      end
    end

    describe "DELETE destroy" do
      it "deletes the problem" do
        expect {
          delete :destroy, params: { id: problem.id }
        }.to change(Problem, :count).by(-1)
      end
    end
  end
end
