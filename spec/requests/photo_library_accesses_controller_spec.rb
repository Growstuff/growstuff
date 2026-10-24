# frozen_string_literal: true

require 'rails_helper'

describe PhotoLibraryAccessesController do
  let(:member) { create(:member) }
  let!(:admin) { create(:admin_member) }

  describe '#create' do
    subject(:ask) { post photo_library_access_path, params: { photo_library_access: { request_message: 'My garden' } } }

    context 'when signed in' do
      before { sign_in member }

      it 'records the request' do
        ask
        expect(member.reload.photo_library_status).to eq 'requested'
      end

      it 'emails the admins' do
        expect { ask }.to change { ActionMailer::Base.deliveries.map(&:to) }.to include([admin.email])
      end

      it 'goes back to the photos tab of the account page' do
        ask
        expect(response).to redirect_to("#{edit_member_registration_path}#photos")
      end
    end

    context 'when asking twice' do
      before do
        sign_in member
        post photo_library_access_path
      end

      it 'does not email the admins again' do
        expect { ask }.not_to(change { ActionMailer::Base.deliveries.size })
      end
    end

    context 'when signed out' do
      it 'records nothing' do
        expect { ask }.not_to change(PhotoLibraryAccess, :count)
      end
    end
  end
end
