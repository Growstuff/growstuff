class AuthenticationsController < ApplicationController
  before_filter :authenticate_member!
  load_and_authorize_resource

  # POST /authentications
  def create
    auth = request.env['omniauth.auth']
    @authentication = nil
    if auth

      name = ''
      case auth['provider']
      when 'twitter'
        name = auth['info']['nickname']
      when 'flickr', 'facebook'
        name = auth['info']['name']
      else
        name = auth['info']['name']
      end

      @authentication = current_member.authentications
      .create_with(
        name: name,
        token: auth['credentials']['token'],
        secret: auth['credentials']['secret']
      )
      .find_or_create_by(
        provider: auth['provider'],
        uid: auth['uid'],
        name: name)

      flash[:notice] = "Authentication successful."
    else
      flash[:notice] = "Authentication failed."
    end
    redirect_to request.env['omniauth.origin'] || edit_member_registration_path
  end

  # DELETE /authentications/1
  def destroy
    @authentication = Authentication.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to edit_member_registration_path }
    end
  end
end
