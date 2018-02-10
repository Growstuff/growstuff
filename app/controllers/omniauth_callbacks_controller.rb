require './lib/actions/oauth_signup_action'

#
# Handle signup or signin
# from various oauth providers
#
# Heavily overlaps with Authentications controller
#
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def facebook
    create
  end

  def failure
    flash[:alert] = "Authentication failed."
    redirect_to request.env['omniauth.origin'] || "/"
  end

  private

  def create
    auth = request.env['omniauth.auth']
    action = Growstuff::OauthSignupAction.new

    @authentication = nil

    return redirect_to request.env['omniauth.origin'] || edit_member_registration_path unless auth

    member = action.find_or_create_from_authorization(auth)
    @authentication = action.establish_authentication(auth, member)

    if action.member_created?
      raise "Invalid provider" unless %w(facebook twitter flickr).index(auth['provider'].to_s)

      session["devise.#{auth['provider']}_data"] = request.env["omniauth.auth"]
      sign_in member
      redirect_to finish_signup_url(member)
    else
      sign_in_and_redirect member, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: auth['provider']) if is_navigational_format?
    end
  end

  def after_sign_in_path_for(resource)
    if resource.tos_agreement
      super resource
    else
      finish_signup_path(resource)
    end
  end
end
