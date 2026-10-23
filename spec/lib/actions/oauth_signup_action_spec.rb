# frozen_string_literal: true

require 'rails_helper'
require './lib/actions/oauth_signup_action'

describe Growstuff::OauthSignupAction do
  subject(:action) { described_class.new }

  let(:email) { 'no.existing.user@gmail.com' }
  let(:avatar) { 'http://cl.jroo.me/z3/W/H/K/e/a.baa-very-cool-hat-you-.jpg' }
  let(:auth) do
    OmniAuth::AuthHash.new('provider'    => 'facebook',
                           'uid'         => '123545',
                           'info'        => {
                             'name'     => "John Testerson's Brother",
                             'nickname' => 'JohnnyB',
                             'email'    => email,
                             'image'    => 'http://findicons.com/files/icons/1072/face_avatars/300/i04.png'
                           },
                           'credentials' => {
                             'token'  => "token",
                             'secret' => "donttell"
                           })
  end
  let(:member) { action.find_or_create_from_authorization(auth) }
  let(:authentication) { action.establish_authentication(auth, member) }

  shared_examples 'stores the uid and provider' do
    it { expect(authentication.member).to eq member }
    it { expect(authentication.provider).to eq 'facebook' }
    it { expect(authentication.uid).to eq '123545' }
  end

  context 'with no existing user' do
    before { authentication }

    it { is_expected.to be_member_created }
    it { expect(member.email).to eq email }
    it { expect(member.login_name).to eq 'JohnnyB' }
    it { expect(member.preferred_avatar_uri).to eq auth['info']['image'] }
    it { expect(member.password).not_to be_nil }
    it { expect(member.tos_agreement).to be_nil }

    it_behaves_like 'stores the uid and provider'
  end

  context 'with an existing user who has never used oauth' do
    let(:email) { 'never.used.oauth@yahoo.com' }
    let!(:existing_member) { create(:member, email:, login_name: 'existing', preferred_avatar_uri: avatar) }

    before { authentication }

    it { is_expected.not_to be_member_created }
    it { expect(member).to eq existing_member }
    it { expect(member.login_name).to eq 'existing' }
    it { expect(member.preferred_avatar_uri).to eq avatar }

    it_behaves_like 'stores the uid and provider'
  end

  context 'with an existing user who has used oauth' do
    let(:email) { 'i.used.oauth.once@coolemail.com' }
    let!(:existing_member) { create(:member, email:, login_name: 'schrodingerscat', preferred_avatar_uri: avatar) }
    let!(:existing_authentication) do
      existing_member.authentications.create(provider: 'facebook', uid: '123545', name: "John Testerson's Brother")
    end

    before { authentication }

    it { is_expected.not_to be_member_created }
    it { expect(member).to eq existing_member }
    it { expect(member.login_name).to eq 'schrodingerscat' }
    it { expect(member.preferred_avatar_uri).to eq avatar }
    it { expect(authentication).to eq existing_authentication }
  end
end
