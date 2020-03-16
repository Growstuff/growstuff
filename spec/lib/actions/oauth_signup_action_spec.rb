# frozen_string_literal: true

require 'rails_helper'
require './lib/actions/oauth_signup_action'

describe 'Growstuff::OauthSignupAction' do
  before do
    @action = Growstuff::OauthSignupAction.new
  end

  context 'with a valid authentication' do
    before do
      @auth = OmniAuth::AuthHash.new('provider'    => 'facebook',
                                     'uid'         => '123545',
                                     'info'        => {
                                       'name'     => "John Testerson's Brother",
                                       'nickname' => 'JohnnyB',
                                       'email'    => 'example.oauth.facebook@example.com',
                                       'image'    => 'http://findicons.com/files/icons/1072/face_avatars/300/i04.png'
                                     },
                                     'credentials' => {
                                       'token'  => "token",
                                       'secret' => "donttell"
                                     })
    end

    context 'no existing user' do
      before do
        @auth['info']['email'] = 'no.existing.user@gmail.com'

        Member.where(email: @auth['info']['email']).delete_all

        @member = @action.find_or_create_from_authorization(@auth)
        @authentication = @action.establish_authentication(@auth, @member)
      end

      after do
        @member.delete
        @authentication.delete
      end

      it 'creates a new user' do
        expect(@action.member_created?).to eq true
      end

      it 'sets the right email' do
        expect(@member.email).to eq @auth['info']['email']
      end

      it 'generates a login_name' do
        expect(@member.login_name).to eq 'JohnnyB'
      end

      it 'sets an avatar' do
        expect(@member.preferred_avatar_uri).to eq @auth['info']['image']
      end

      it 'generates a random password' do
        expect(@member.password).not_to eq nil
      end

      it 'does not agree to the tos' do
        expect(@member.tos_agreement).to eq nil
      end

      it 'stores the uid and provider for the member' do
        expect(@authentication.member.id).to eq @member.id
        expect(@authentication.provider).to eq 'facebook'
        expect(@authentication.uid).to eq '123545'
      end
    end

    context 'an existing user' do
      context 'who has never used oauth' do
        before do
          @auth['info']['email'] = 'never.used.oauth@yahoo.com'

          Member.where(email: @auth['info']['email']).delete_all
          @existing_member = create :member,             email:                @auth['info']['email'],
                                                         login_name:           'existing',
                                                         preferred_avatar_uri: 'http://cl.jroo.me/z3/W/H/K/e/a.baa-very-cool-hat-you-.jpg'

          @member = @action.find_or_create_from_authorization(@auth)
          @authentication = @action.establish_authentication(@auth, @member)
        end

        after do
          @existing_member.delete
          @member.delete
          @authentication.delete
        end

        it 'does not create a new user' do
          expect(@action.member_created?).to eq nil
        end

        it 'locates the existing member by email' do
          expect(@member.id).to eq @existing_member.id
        end

        it 'does not generate a login_name' do
          expect(@member.login_name).to eq 'existing'
        end

        it 'does not change the avatar' do
          expect(@member.preferred_avatar_uri).to eq 'http://cl.jroo.me/z3/W/H/K/e/a.baa-very-cool-hat-you-.jpg'
        end

        it 'stores the uid and provider for the member' do
          expect(@authentication.member.id).to eq @member.id
          expect(@authentication.provider).to eq 'facebook'
          expect(@authentication.uid).to eq '123545'
        end
      end

      context 'who has used oauth' do
        before do
          @auth['info']['email'] = 'i.used.oauth.once@coolemail.com'

          Member.where(email: @auth['info']['email']).delete_all
          Authentication.delete_all

          @existing_member = create :member, email:                @auth['info']['email'],
                                             login_name:           'schrodingerscat',
                                             preferred_avatar_uri: 'http://cl.jroo.me/z3/W/H/K/e/a.baa-very-cool-hat-you-.jpg'

          @existing_authentication = @existing_member.authentications.create(provider:  'facebook',
                                                                             uid:       '123545',
                                                                             name:      "John Testerson's Brother",
                                                                             member_id: @existing_member.id)

          @member = @action.find_or_create_from_authorization(@auth)
          @authentication = @action.establish_authentication(@auth, @member)
        end

        after do
          @existing_member.delete
          @member.delete
          @existing_authentication.delete
          @authentication.delete
        end

        it 'does not create a new user' do
          expect(@action.member_created?).to eq nil
        end

        it 'locates the existing member by uid and provider' do
          expect(@member.id).to eq @existing_member.id
        end

        it 'does not generate a login_name' do
          expect(@member.login_name).to eq 'schrodingerscat'
        end

        it 'does not change the avatar' do
          expect(@member.preferred_avatar_uri).to eq 'http://cl.jroo.me/z3/W/H/K/e/a.baa-very-cool-hat-you-.jpg'
        end

        it 'locates the existing uid and provider for the member' do
          expect(@authentication.id).to eq @existing_authentication.id
        end
      end
    end
  end
end
