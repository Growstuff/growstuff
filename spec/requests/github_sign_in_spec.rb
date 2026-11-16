# frozen_string_literal: true

require 'rails_helper'

describe 'Signing in with GitHub' do
  let(:auth_hash) do
    OmniAuth::AuthHash.new(provider: 'github', uid: '123',
                          info: { nickname: 'alice', name: 'alice', image: 'https://avatars.githubusercontent.com/u/123' },
                          credentials: { token: 'private-token' })
  end

  before do
    allow(OmniAuth::Strategies::GrowstuffGithub).to receive(:enabled?).and_return(true)
    OmniAuth.config.mock_auth[:github] = auth_hash
  end

  after { OmniAuth.config.mock_auth[:github] = nil }

  def callback(tos: '1')
    post member_github_omniauth_authorize_path, params: { tos_agreement: tos }
    get member_github_omniauth_callback_path
  end

  context 'when new to Growstuff' do
    it 'creates a member' do
      expect { callback }.to change(Member, :count).by(1)
    end

    it 'does not require an email' do
      callback
      expect(Member.last.email).to be_nil
    end

    it 'suggests the GitHub login as a username' do
      callback
      expect(Member.last.login_name).to eq 'alice'
    end

    it 'links the stable identity' do
      callback
      expect(Member.last.auth('github').uid).to eq '123'
    end

    it 'does not persist the access token' do
      callback
      expect(Member.last.auth('github').token).to be_nil
    end

    it 'records agreement to the terms' do
      callback
      expect(Member.last).to be_tos_agreement
    end

    it 'signs in the new member' do
      callback
      get edit_member_registration_path
      expect(response).to have_http_status(:ok)
    end

    it 'requires terms acceptance if it was not already given' do
      callback(tos: nil)
      expect(response).to redirect_to finish_signup_path(Member.last)
    end

    context 'with another member without email' do
      before { create(:member, email: nil, email_optional: true) }

      it 'creates a separate account' do
        expect { callback }.to change(Member, :count).by(1)
      end
    end
  end

  context 'when returning to a linked account' do
    let(:member) { create(:member, email: nil, email_optional: true) }

    before { create(:authentication, member:, provider: 'github', uid: '123', name: 'old-name') }

    it 'does not create another member' do
      expect { callback(tos: nil) }.not_to change(Member, :count)
    end

    it 'signs in after a GitHub username change' do
      callback(tos: nil)
      get edit_member_registration_path
      expect(response).to have_http_status(:ok)
    end

    it 'refreshes the displayed login' do
      callback
      expect(member.auth('github').name).to eq 'alice'
    end
  end

  context 'when already signed in' do
    let(:member) { create(:member) }

    before { sign_in member }

    it 'connects GitHub to the current member' do
      expect { callback }.to change { member.authentications.where(provider: 'github').count }.by(1)
    end

    it 'returns to settings' do
      callback
      expect(response).to redirect_to edit_member_registration_path
    end

    context 'with an identity already linked to someone else' do
      before { create(:authentication, provider: 'github', uid: '123') }

      it 'does not connect the identity' do
        expect { callback }.not_to change { member.authentications.count }
      end
    end
  end

  describe 'entry points' do
    it 'offers GitHub on the home page' do
      get root_path
      expect(response.parsed_body.at_css('[data-auth-dialog="github"]')).to be_present
    end

    it 'offers a form without JavaScript' do
      get new_member_session_path
      expect(response.parsed_body.at_css('form[action="/members/auth/github"][method="post"]')).to be_present
    end

    it 'does not ask returning members to accept terms' do
      get new_member_session_path
      expect(response.parsed_body.css('form[action="/members/auth/github"] input[name="tos_agreement"]')).to be_empty
    end

    it 'requires signup consent' do
      get new_member_registration_path
      expect(response.parsed_body.at_css('form[action="/members/auth/github"] input[name="tos_agreement"][required]')).to be_present
    end

    context 'without configuration' do
      before { allow(OmniAuth::Strategies::GrowstuffGithub).to receive(:enabled?).and_return(false) }

      it 'hides the sign in form' do
        get new_member_session_path
        expect(response.parsed_body.css('form[action="/members/auth/github"]')).to be_empty
      end
    end
  end

  describe 'disconnecting' do
    let(:member) { create(:member, email: nil, email_optional: true) }
    let(:authentication) { create(:authentication, member:, provider: 'github', uid: '123') }

    before do
      authentication
      sign_in member
    end

    it 'keeps the only sign in method for a member without email' do
      expect { delete authentication_path(authentication) }.not_to change(Authentication, :count)
    end
  end
end
