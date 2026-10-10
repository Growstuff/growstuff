# frozen_string_literal: true

require 'rails_helper'

describe ForumsController do
  let(:admin) { create(:admin_member) }
  let(:member) { create(:member) }
  let(:forum) { create(:forum) }

  describe "GET #index" do
    it "returns a success response" do
      get :index
      expect(response).to be_successful
    end

    it "assigns @forums" do
      forum # create forum
      get :index
      expect(assigns(:forums)).to include(forum)
    end
  end

  describe "GET #show" do
    it "returns a success response" do
      get :show, params: { id: forum.to_param }
      expect(response).to be_successful
    end
  end

  context "as an admin" do
    before { sign_in admin }

    describe "GET #new" do
      it "returns a success response" do
        get :new
        expect(response).to be_successful
      end
    end

    describe "GET #edit" do
      it "returns a success response" do
        get :edit, params: { id: forum.to_param }
        expect(response).to be_successful
      end
    end

    describe "POST #create" do
      context "with valid params" do
        let(:valid_attributes) { { name: "New Forum", description: "A new forum", owner_id: admin.id } }

        it "creates a new Forum" do
          expect do
            post :create, params: { forum: valid_attributes }
          end.to change(Forum, :count).by(1)
        end

        it "redirects to the created forum" do
          post :create, params: { forum: valid_attributes }
          expect(response).to redirect_to(Forum.last)
        end
      end
    end

    describe "PUT #update" do
      context "with valid params" do
        let(:new_attributes) { { name: "Updated Name" } }

        it "updates the requested forum" do
          put :update, params: { id: forum.to_param, forum: new_attributes }
          forum.reload
          expect(forum.name).to eq("Updated Name")
        end

        it "redirects to the forum" do
          put :update, params: { id: forum.to_param, forum: new_attributes }
          expect(response).to redirect_to(forum)
        end
      end
    end

    describe "DELETE #destroy" do
      it "destroys the requested forum" do
        forum # ensure forum exists
        expect do
          delete :destroy, params: { id: forum.to_param }
        end.to change(Forum, :count).by(-1)
      end

      it "redirects to the forums list" do
        delete :destroy, params: { id: forum.to_param }
        expect(response).to redirect_to(forums_url)
      end
    end
  end

  context "as a regular member" do
    before { sign_in member }

    describe "GET #new" do
      it "denies access" do
        get :new
        expect(response).to redirect_to(root_path)
      end
    end

    describe "POST #create" do
      it "denies access" do
        post :create, params: { forum: { name: "Forbidden" } }
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
