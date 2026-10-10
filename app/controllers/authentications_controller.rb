# frozen_string_literal: true

require './lib/actions/oauth_signup_action'
class AuthenticationsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  skip_load_and_authorize_resource only: :connected

  # POST /authentications
  def create
    auth = request.env['omniauth.auth']
    @authentication = nil
    if auth
      name = Growstuff::OauthSignupAction.new.determine_name(auth)

      @authentication = current_member.authentications
        .create_with(
          name:,
          token:  auth['credentials']['token'],
          secret: auth['credentials']['secret']
        )
        .find_or_create_by(
          provider: auth['provider'],
          uid:      auth['uid'],
          name:
        )

      flash[:notice] = t('messages.auth_success')
    else
      flash[:notice] = t('messages.auth_failed')
    end
    redirect_to request.env['omniauth.origin'] || edit_member_registration_path
  end

  # Where the pop-up that connects an account from a dialog ends up (see
  # AddPhotoModal): it says how it went and closes itself. The dialog notices the
  # connection by asking the server, so it doesn't depend on this page.
  def connected
    @connected = current_member.auth('flickr').present?
    render layout: false
  end

  # DELETE /authentications/1
  def destroy
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to edit_member_registration_path }
    end
  end
end
