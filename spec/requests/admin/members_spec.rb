# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin::Members', type: :request do
  let(:admin_role) { create(:role, name: 'admin') }
  let(:admin) { create(:member, roles: [admin_role]) }
  let!(:active_member) do
    create(
      :member,
      login_name: 'active_spammer',
      email: 'active@example.com',
      bio: 'A' * 300,
      photos_count: 3,
      plantings_count: 5,
      forums_count: 1,
      gardens_count: 2,
      harvests_count: 4,
      jobs_count: 6,
      confirmed_at: Time.current,
      last_sign_in_at: Time.current
    )
  end
  let!(:deleted_member) do
    member = create(:member, login_name: 'deleted_user', email: 'deleted@example.com')
    member.discard
    member
  end

  before do
    login_as admin, scope: :member
  end

  describe 'GET /admin/members' do
    context 'by default (Active tab)' do
      it 'filters out deleted members and shows active members' do
        get admin_members_path
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('active_spammer')
        expect(response.body).not_to include('deleted_user')
      end

      it 'surfaces login name, email, confirmed status, last login, truncated bio, and count attributes' do
        get admin_members_path
        expect(response.body).to include('active@example.com')
        expect(response.body).to include('A' * 252 + '...') # truncated to 255 chars
        expect(response.body).to include('Photos')
        expect(response.body).to include('Plantings')
        expect(response.body).to include('Forums')
        expect(response.body).to include('Gardens')
        expect(response.body).to include('Harvests')
        expect(response.body).to include('Jobs')
      end

      it 'displays the spam score column and badge' do
        get admin_members_path
        expect(response.body).to include('Spam Score')
        expect(response.body).to include('spam-score-badge')
      end
    end

    context 'when requesting deactivated tab (status=deactivated)' do
      it 'shows discarded members and excludes active members' do
        get admin_members_path(status: 'deactivated')
        expect(response).to have_http_status(:ok)
        expect(response.body).to include('deleted_user')
        expect(response.body).not_to include('active_spammer')
      end

      it 'displays the spam score column' do
        get admin_members_path(status: 'deactivated')
        expect(response.body).to include('Spam Score')
      end
    end
  end

  describe 'POST /admin/members/bulk_ban' do
    it 'discards selected active members' do
      expect do
        post bulk_ban_admin_members_path, params: { member_ids: [active_member.id] }
      end.to change { active_member.reload.discarded? }.from(false).to(true)

      expect(response).to redirect_to(admin_members_path)
    end

    it 'does not allow admin to ban themselves via bulk ban' do
      post bulk_ban_admin_members_path, params: { member_ids: [admin.id] }
      expect(admin.reload.discarded?).to be false
    end
  end

  describe 'POST /admin/members/:slug/restore' do
    it 'undiscards a deactivated member' do
      expect do
        post restore_admin_member_path(deleted_member)
      end.to change { deleted_member.reload.discarded? }.from(true).to(false)

      expect(response).to redirect_to(admin_members_path(status: 'deactivated'))
    end
  end
end
