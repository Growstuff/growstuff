# frozen_string_literal: true

require 'rails_helper'

describe 'Signing in with Bluesky' do
  include Devise::Test::IntegrationHelpers

  let(:did) { 'did:plc:abcdefghijklmnopqrstuvwx' }
  let(:auth_hash) do
    OmniAuth::AuthHash.new(provider: 'bluesky', uid: did,
                           info: { name: 'alice.bsky.social', nickname: 'alice.bsky.social', handle: 'alice.bsky.social' },
                           credentials: {})
  end

  before { OmniAuth.config.mock_auth[:bluesky] = auth_hash }

  after { OmniAuth.config.mock_auth[:bluesky] = nil }

  # Starting from the form, which is where the Terms of Service get agreed to.
  def callback(tos: '1')
    post '/members/auth/bluesky', params: { handle: 'alice.bsky.social', tos_agreement: tos }
    get '/members/auth/bluesky/callback'
  end

  context 'when new to Growstuff' do
    it 'creates a member' do
      expect { callback }.to change(Member, :count).by(1)
    end

    it 'creates a member without an email' do
      callback

      expect(Member.last.email).to be_nil
    end

    it 'suggests the handle as the login name' do
      callback

      expect(Member.last.login_name).to eq('alice_bsky_social')
    end

    it 'remembers the handle on the profile' do
      callback

      expect(Member.last.bluesky_handle).to eq('alice.bsky.social')
    end

    it 'links the DID' do
      callback

      expect(Member.last.auth('bluesky').uid).to eq(did)
    end

    it 'asks them to finish signing up' do
      callback

      expect(response).to redirect_to(finish_signup_url(Member.last))
    end

    it 'records that they agreed to the terms' do
      callback

      expect(Member.last.tos_agreement).to be(true)
    end

    it 'does not make a member who has not agreed to the terms' do
      expect { callback(tos: nil) }.not_to change(Member, :count)
    end

    it 'sends them back to the terms when they have not agreed' do
      callback(tos: nil)

      expect(flash[:alert]).to eq(I18n.t('messages.tos_required'))
    end

    it 'does not log them in as another member who also has no email' do
      other = create(:member)
      other.update_column(:email, nil) # rubocop:disable Rails/SkipsModelValidations

      expect { callback }.to change(Member, :count).by(1)
    end
  end

  context 'when already a member' do
    let!(:member) { create(:member, email: nil, email_optional: true) }

    before { create(:authentication, member:, provider: 'bluesky', uid: did, name: 'old.bsky.social') }

    it 'does not create another member' do
      expect { callback }.not_to change(Member, :count)
    end

    it 'signs them in without asking for the terms again' do
      expect { callback(tos: nil) }.not_to change(Member, :count)
    end

    it 'follows a changed handle' do
      callback

      expect(member.auth('bluesky').name).to eq('alice.bsky.social')
    end
  end

  context 'when signed in already' do
    let(:member) { create(:member) }

    before { sign_in member }

    it 'links Bluesky to them' do
      callback

      expect(member.auth('bluesky').uid).to eq(did)
    end

    it 'refuses an account that belongs to someone else' do
      create(:authentication, provider: 'bluesky', uid: did)
      callback

      expect(member.auth('bluesky')).to be_nil
    end
  end

  describe 'disconnecting' do
    let(:member) { create(:member, email: nil, email_optional: true) }
    let!(:authentication) { create(:authentication, member:, provider: 'bluesky', uid: did) }

    before { sign_in member }

    it 'keeps the only way a member without an email can sign in' do
      expect { delete authentication_path(authentication) }.not_to change(Authentication, :count)
    end

    it 'lets a member with an email disconnect' do
      member.skip_reconfirmation!
      member.update!(email: 'alice@example.com')

      expect { delete authentication_path(authentication) }.to change(Authentication, :count).by(-1)
    end
  end

  describe 'the sign in page' do
    it 'offers Bluesky when a signing key is configured' do
      allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key)
      get new_member_session_path

      expect(response.body).to include('Bluesky handle')
    end

    it 'links to the Bluesky dialog from the home page when a signing key is configured' do
      allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key)
      get root_path

      expect(response.body).to include('data-auth-dialog="bluesky"')
    end

    it 'passes the dialog where to post the handle' do
      allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key)
      get root_path

      expect(response.body).to include('/members/auth/bluesky')
    end

    it 'keeps Bluesky off the forgotten password page' do
      allow(Atproto::ClientConfig).to receive(:private_key).and_return(Atproto::Jws.generate_key)
      get new_member_password_path

      expect(response.body).not_to include('Bluesky handle')
    end

    it 'hides Bluesky without a signing key' do
      get new_member_session_path

      expect(response.body).not_to include('Bluesky handle')
    end

    it 'has no Bluesky link on the home page without a signing key' do
      get root_path

      expect(response.body).not_to include('data-auth-dialog="bluesky"')
    end
  end
end
