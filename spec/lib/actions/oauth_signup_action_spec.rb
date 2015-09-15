require 'rails_helper'
require './lib/actions/oauth_signup_action'

describe 'Growstuff::OauthSignupAction' do
  before :each do
    @action = Growstuff::OauthSignupAction.new
  end

  context 'with a valid authentication' do
    before :each do
      @auth = OmniAuth::AuthHash.new({
        'provider' => 'facebook',
        'uid' => '123545',
        'info' => {
          'name' => "John Testerson",
          'nickname' => 'JohnnyT',
          'email' => 'example.oauth.facebook@example.com',
          'image' => 'http://findicons.com/files/icons/1072/face_avatars/300/i04.png'
        },
        'credentials' => {
          'token' => "token",
          'secret' => "donttell"
        }
      })
    end

    context 'no existing user' do
      before :each do
        @auth['info']['email'] = 'no.existing.user@gmail.com'

        Member.where(email:  @auth['info']['email']).delete_all

        @member = @action.find_or_create_from_authorization(@auth)
        @authentication = @action.establish_authentication(@auth, @member)
      end
      it 'should create a new user' do
        expect(@action.member_created?).to eq true
      end

      it 'should set the right email' do
        expect(@member.email).to eq @auth['info']['email']
      end

      it 'should generate a login_name' do
        expect(@member.login_name).to eq 'JohnnyT'
      end

      it 'should set an avatar' do
        expect(@member.preferred_avatar_uri).to eq @auth['info']['image']
      end

      it 'should generate a random password' do
        expect(@member.password).not_to eq nil
      end

      it 'should not agree to the tos'

      it 'should store the uid and provider for the member' do
        expect(@authentication.member.id).to eq @member.id
        expect(@authentication.provider).to eq 'facebook'
        expect(@authentication.uid).to eq '123545' 
      end
    end

    context 'an existing user' do
      context 'who has never used oauth' do
      end
      context 'who has used oauth' do
      end
    end
  end
end