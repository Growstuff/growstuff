# frozen_string_literal: true

require 'rails_helper'

describe OmniauthCallbacksController, type: :controller do
  let(:profile_url) { 'https://mastodon.social/@alice' }
  let(:uid) { '111' }
  let(:auth) do
    OmniAuth::AuthHash.new(provider:    'mastodon',
                           uid:         uid,
                           info:        { nickname: 'alice', name: 'alice', urls: { 'Profile' => profile_url } },
                           credentials: { token: 'secret-token', secret: nil })
  end

  before do
    request.env['devise.mapping'] = Devise.mappings[:member]
    request.env['omniauth.auth'] = auth
  end

  describe 'GET #mastodon' do
    context 'when signed out, with an account that is already linked' do
      let!(:member) { create(:member) }

      before { create(:mastodon_authentication, member:, uid: '111@mastodon.social') }

      it 'signs the member in' do
        get :mastodon
        expect(controller.current_member).to eq member
      end
    end

    context 'when signed out, with an account nobody has linked' do
      it 'does not sign anyone in' do
        get :mastodon
        expect(controller.current_member).to be_nil
      end

      it 'sends them to join' do
        get :mastodon
        expect(response).to redirect_to new_member_registration_path
      end

      it 'explains why' do
        get :mastodon
        expect(flash[:alert]).to eq I18n.t('messages.tos_required')
      end

      it 'does not create a member' do
        expect { get :mastodon }.not_to change(Member, :count)
      end
    end

    context 'when signed out, and another server has an account with the same number' do
      let(:profile_url) { 'https://example.social/@bob' }

      before do
        create(:mastodon_authentication, member: create(:member), uid: '111@mastodon.social')
      end

      it 'does not sign in the member who has the other account' do
        get :mastodon
        expect(controller.current_member).to be_nil
      end
    end

    context 'when signed in' do
      let(:member) { create(:member) }

      before { sign_in member }

      it 'connects the account' do
        expect { get :mastodon }.to change { member.authentications.count }.by(1)
      end

      it 'records which server the account is on' do
        get :mastodon
        expect(member.authentications.last.uid).to eq '111@mastodon.social'
      end

      it 'names the account in full' do
        get :mastodon
        expect(member.authentications.last.name).to eq '@alice@mastodon.social'
      end

      it 'does not keep the access token' do
        get :mastodon
        expect(member.authentications.last.token).to be_nil
      end

      it 'says it worked' do
        get :mastodon
        expect(flash[:notice]).to eq I18n.t('messages.auth_success')
      end

      context 'with an account on another server already connected' do
        before { create(:mastodon_authentication, member:, uid: '111@example.social', name: '@alice@example.social') }

        it 'connects this one as well' do
          expect { get :mastodon }.to change { member.authentications.count }.by(1)
        end
      end

      context 'with this account already connected under an old name' do
        before { create(:mastodon_authentication, member:, uid: ['111', 'mastodon.social'].join('@'), name: 'Old name') }

        it 'reuses the existing connection' do
          expect { get :mastodon }.not_to(change { member.authentications.count })
        end

        it 'updates the displayed name' do
          get :mastodon
          expect(member.authentications.last.name).to eq ['@alice', 'mastodon.social'].join('@')
        end
      end
    end

    context 'when signed in, but someone else has already connected that account' do
      let(:member) { create(:member) }

      before do
        create(:mastodon_authentication, member: create(:member), uid: '111@mastodon.social')
        sign_in member
      end

      it 'does not connect it again' do
        expect { get :mastodon }.not_to(change { member.authentications.count })
      end

      it 'says so' do
        get :mastodon
        expect(flash[:alert]).to eq I18n.t('messages.auth_taken')
      end
    end

    context 'when joining with terms accepted' do
      before { request.env['omniauth.params'] = { 'tos_agreement' => '1' } }

      it 'creates a member without an email' do
        expect { get :mastodon }.to change(Member, :count).by(1)
      end

      it 'signs the new member in' do
        get :mastodon
        expect(controller.current_member).to be_present
      end

      it 'records agreement to the terms' do
        get :mastodon
        expect(controller.current_member.tos_agreement).to be true
      end
    end

    context 'when the profile address is missing' do
      let(:profile_url) { nil }

      before { sign_in create(:member) }

      it 'is treated as a failed login' do
        get :mastodon
        expect(flash[:alert]).to eq I18n.t('messages.auth_failed')
      end
    end
  end
end
