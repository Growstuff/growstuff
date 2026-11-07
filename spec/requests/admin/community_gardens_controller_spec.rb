# frozen_string_literal: true

require 'rails_helper'

describe Admin::CommunityGardensController, type: :request do
  let(:admin_role) { create(:role, name: 'admin') }
  let(:admin) { create(:member, roles: [admin_role]) }
  let(:regular_member) { create(:member) }
  let!(:community_garden) { create(:community_garden, title: 'Old Sunshine Garden') }

  context 'when signed in as an admin' do
    before { login_as admin, scope: :member }

    describe 'GET /admin/community_gardens' do
      it 'renders index successfully' do
        get admin_community_gardens_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Old Sunshine Garden')
      end
    end

    describe 'GET /admin/community_gardens/:id' do
      it 'shows details of community garden' do
        get admin_community_garden_path(community_garden)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Old Sunshine Garden')
      end
    end

    describe 'GET /admin/community_gardens/new' do
      it 'renders new form' do
        get new_admin_community_garden_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'POST /admin/community_gardens' do
      it 'creates a new community garden' do
        params = {
          community_garden: {
            title: 'New Neighborhood Plot',
            website: 'https://example.org/new',
            coordinates: '-37.8, 144.9',
            wikidata_id: 'Q999',
            osm_id: 'way/888',
            description: 'A brand new community garden',
            email: 'new@example.org'
          }
        }
        expect do
          post admin_community_gardens_path, params: params
        end.to change(CommunityGarden, :count).by(1)

        expect(response).to redirect_to(admin_community_gardens_path)
      end
    end

    describe 'GET /admin/community_gardens/:id/edit' do
      it 'renders edit form' do
        get edit_admin_community_garden_path(community_garden)
        expect(response).to have_http_status(:ok)
      end
    end

    describe 'PATCH /admin/community_gardens/:id' do
      it 'updates community garden' do
        patch admin_community_garden_path(community_garden), params: { community_garden: { title: 'Updated Garden Title' } }
        expect(response).to redirect_to(admin_community_gardens_path)
        expect(community_garden.reload.title).to eq('Updated Garden Title')
      end
    end

    describe 'DELETE /admin/community_gardens/:id' do
      it 'destroys community garden' do
        expect do
          delete admin_community_garden_path(community_garden)
        end.to change(CommunityGarden, :count).by(-1)

        expect(response).to redirect_to(admin_community_gardens_path)
      end
    end
  end

  context 'when signed in as a non-admin member' do
    before { login_as regular_member, scope: :member }

    it 'denies access to index' do
      get admin_community_gardens_path
      expect(response).to redirect_to(root_path)
    end
  end

  context 'when signed out' do
    it 'redirects to sign in' do
      get admin_community_gardens_path
      expect(response).to redirect_to(new_member_session_path)
    end
  end
end
