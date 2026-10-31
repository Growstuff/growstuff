# frozen_string_literal: true

require './lib/actions/oauth_signup_action'

#
# Handle signup or signin
# from various oauth providers
#
# Heavily overlaps with Authentications controller
#
class OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Devise calls the action named for the provider.
  Authentication::SIGN_IN_PROVIDERS.each_key do |provider|
    define_method(provider) { create }
  end

  def failure
    flash[:alert] = failure_message
    redirect_to request.env['omniauth.origin'] || "/"
  end

  private

  def failure_message
    return t('messages.auth_failed') unless request.env['omniauth.strategy']&.name == 'bluesky'

    case request.env['omniauth.error.type']
    when :request_expired then t('messages.bluesky_expired')
    when :access_denied then t('messages.bluesky_declined')
    else t('messages.bluesky_failed')
    end
  end

  def create
    auth = request.env['omniauth.auth']
    action = Growstuff::OauthSignupAction.new

    @authentication = nil

    return redirect_to request.env['omniauth.origin'] || edit_member_registration_path unless auth
    return connect_to_current_member(action, auth) if current_member

    return refuse_without_terms unless action.existing_member(auth) || terms_agreed?

    member = action.find_or_create_from_authorization(auth, tos_agreement: terms_agreed? || nil)
    @authentication = action.establish_authentication(auth, member)

    if action.member_created?
      raise "Invalid provider" unless (%w(flickr) + Authentication::SIGN_IN_PROVIDERS.keys).include?(auth['provider'].to_s)

      session["devise.#{auth['provider']}_data"] = request.env["omniauth.auth"]
      sign_in member
      redirect_to finish_signup_url(member)
    else
      sign_in_and_redirect member, event: :authentication # this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: auth['provider']) if is_navigational_format?
    end
  end

  # What they ticked on the form before leaving for the provider, which OmniAuth keeps for the way back.
  def terms_agreed?
    request.env['omniauth.params']&.dig('tos_agreement') == '1'
  end

  def refuse_without_terms
    redirect_to request.env['omniauth.origin'] || new_member_registration_path, alert: t('messages.tos_required')
  end

  # Someone already signed in is adding this account to their own, not signing in as someone else.
  def connect_to_current_member(action, auth)
    taken = Authentication.where(provider: auth['provider'], uid: auth['uid']).where.not(member_id: current_member.id).exists?
    if taken
      flash[:alert] = t('messages.auth_taken')
    else
      action.establish_authentication(auth, current_member)
      flash[:notice] = t('messages.auth_success')
    end
    redirect_to edit_member_registration_path
  end

  def after_sign_in_path_for(resource)
    if resource.tos_agreement
      super
    else
      finish_signup_path(resource)
    end
  end
end
