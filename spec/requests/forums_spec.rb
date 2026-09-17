# frozen_string_literal: true

require 'rails_helper'

describe "Forums" do
  let(:admin) { create(:admin_member) }
  let(:forum) { create(:forum) }

  describe "GET /forums" do
    it "returns a successful response" do
      get forums_path
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON when requested" do
      get forums_path(format: :json)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end
  end

  describe "GET /forums/:id" do
    it "returns a successful response" do
      get forum_path(forum)
      expect(response).to have_http_status(:ok)
    end

    it "returns JSON when requested" do
      get forum_path(forum, format: :json)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("application/json")
    end
  end

  describe "POST /forums" do
    context "as an admin" do
      before { sign_in admin }

      it "creates a new forum" do
        expect do
          post forums_path, params: { forum: { name: "New Request Forum", description: "Desc", owner_id: admin.id } }
        end.to change(Forum, :count).by(1)
        expect(response).to redirect_to(forum_path(Forum.last))
      end
    end

    context "as a guest" do
      it "redirects to sign in or denies access" do
        post forums_path, params: { forum: { name: "New Request Forum", description: "Desc" } }
        # Depending on CanCan/Devise setup, it might be a redirect to login or root
        expect(response).to redirect_to(new_member_session_path).or redirect_to(root_path)
      end
    end
  end
end
