# frozen_string_literal: true

require 'rails_helper'

describe Admin::PhotoLibraryAccessesController do
  let(:admin) { create(:admin_member) }
  let(:access) { create(:photo_library_access) }

  describe '#index' do
    before do
      create(:photo_library_access, member: create(:member, login_name: 'waiting'))
      create(:approved_photo_library_access, member: create(:member, login_name: 'uploader'))
    end

    context 'when an admin' do
      before do
        sign_in admin
        get admin_photo_library_accesses_path
      end

      it 'lists requests waiting' do
        expect(response.body).to include('waiting')
      end

      it 'leaves out approved members' do
        expect(response.body).not_to include('uploader')
      end
    end

    context 'when an admin looking at approved members' do
      before do
        sign_in admin
        get admin_photo_library_accesses_path(status: 'approved')
      end

      it 'lists them' do
        expect(response.body).to include('uploader')
      end
    end

    context 'when not an admin' do
      before do
        sign_in create(:member)
        get admin_photo_library_accesses_path
      end

      it 'is not shown' do
        expect(response.body).not_to include('waiting')
      end
    end
  end

  describe '#approve' do
    subject(:approve) { post approve_admin_photo_library_access_path(access), params: { note: 'Welcome' } }

    context 'when an admin' do
      before { sign_in admin }

      it 'approves the member' do
        approve
        expect(access.reload).to be_approved
      end

      it 'records who approved' do
        approve
        expect(access.reload.decided_by).to eq admin
      end

      it 'emails the member' do
        expect { approve }.to change { ActionMailer::Base.deliveries.map(&:to) }.to include([access.member.email])
      end
    end

    context 'when not an admin' do
      before { sign_in create(:member) }

      it 'changes nothing' do
        approve
        expect(access.reload).to be_requested
      end
    end
  end

  describe '#refuse' do
    before do
      sign_in admin
      post refuse_admin_photo_library_access_path(access)
    end

    it 'refuses the request' do
      expect(access.reload).to be_refused
    end
  end

  describe '#revoke' do
    let(:access) { create(:approved_photo_library_access) }

    before do
      sign_in admin
      post revoke_admin_photo_library_access_path(access)
    end

    it 'takes access away' do
      expect(access.reload).to be_revoked
    end
  end
end
