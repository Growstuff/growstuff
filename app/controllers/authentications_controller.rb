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
    current_member.authentications.create(
      :provider => auth['provider'],
      :uid => auth['uid'],
      :name => auth['info']['nickname'] || auth['info']['name'],
      :token => auth['credentials']['token'],
      :secret => auth['credentials']['secret'])
    flash[:notice] = "Authentication successful."
    redirect_to authentications_url
  end

  # DELETE /authentications/1
  # DELETE /authentications/1.json
  def destroy
    @authentication = Authentication.find(params[:id])
    @authentication.destroy

    respond_to do |format|
      format.html { redirect_to authentications_url }
      format.json { head :no_content }
    end
  end
end
