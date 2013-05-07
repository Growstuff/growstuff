class AuthenticationsController < ApplicationController
  # GET /authentications
  # GET /authentications.json
  def index
    @authentications = current_member.authentications if member_signed_in?

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @authentications }
    end
  end

  # POST /authentications
  # POST /authentications.json
  def create
    auth = request.env['omniauth.auth']
    @authentication = nil
    if auth

      name = ''
      case auth['provider']
      when 'twitter'
        name = auth['info']['nickname']
      when 'flickr'
        name = auth['info']['name']
      else
        name = auth['info']['name']
      end

      @authentication = current_member.authentications.find_or_create_by_provider_and_uid(
        :provider => auth['provider'],
        :uid => auth['uid'],
        :name => name,
        :token => auth['credentials']['token'],
        :secret => auth['credentials']['secret'])
      flash[:notice] = "Authentication successful."
    else
      flash[:notice] = "Authentication failed."
    end
    redirect_to edit_member_registration_path
  end

  # DELETE /authentications/1
  # DELETE /authentications/1.json
  def destroy
    @authentication = Authentication.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to edit_member_registration_path }
      format.json { head :no_content }
    end
  end
end
