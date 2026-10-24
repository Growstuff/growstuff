# frozen_string_literal: true

require 'rails_helper'

describe PhotoLibraryAccess do
  let(:member) { create(:member) }
  let(:admin) { create(:admin_member) }

  describe '.request!' do
    subject(:access) { described_class.request!(member, 'My garden') }

    context 'without an earlier request' do
      it 'is requested' do
        expect(access).to be_requested
      end

      it 'keeps the message' do
        expect(access.request_message).to eq 'My garden'
      end
    end

    context 'when refused before' do
      before { create(:photo_library_access, member:).refuse!(admin, 'Not yet') }

      it 'asks again' do
        expect(access).to be_requested
      end

      it 'clears the earlier decision' do
        expect(access.decided_by).to be_nil
      end
    end

    context 'when already approved' do
      before { create(:approved_photo_library_access, member:) }

      it 'stays approved' do
        expect(access).to be_approved
      end
    end
  end

  describe '#approve!' do
    subject(:access) { create(:photo_library_access, member:) }

    before { access.approve!(admin, 'Welcome') }

    it 'approves the request' do
      expect(access.reload).to be_approved
    end

    it 'records who approved it' do
      expect(access.reload.decided_by).to eq admin
    end

    it 'records when' do
      expect(access.reload.decided_at).to be_present
    end

    it 'keeps the note' do
      expect(access.reload.note).to eq 'Welcome'
    end
  end

  describe '#revoke!' do
    subject(:access) { create(:approved_photo_library_access, member:) }

    before { access.revoke!(admin) }

    it 'takes access away' do
      expect(member.reload.photo_library_status).to eq 'revoked'
    end
  end

  describe 'validations' do
    it 'allows one per member' do
      create(:photo_library_access, member:)
      expect(build(:photo_library_access, member:)).not_to be_valid
    end

    it 'rejects an unknown status' do
      expect(build(:photo_library_access, status: 'maybe')).not_to be_valid
    end
  end

  describe 'Member#photo_library_status' do
    it 'is none before asking' do
      expect(member.photo_library_status).to eq 'none'
    end
  end

  context 'when the deciding admin is deleted' do
    let(:access) { create(:approved_photo_library_access, member:, decided_by: admin) }

    before do
      access
      admin.destroy
    end

    it 'keeps the access' do
      expect(access.reload).to be_approved
    end
  end
end
