class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  after_filter :store_location
  before_filter :set_locale

  def store_location
    if (request.path != "/members/sign_in" &&
        request.path != "/members/sign_up" &&
        request.path != "/members/password/new" &&
        request.path != "/members/password/edit" &&
        request.path != "/members/confirmation" &&
        request.path != "/members/sign_out" &&
        !request.xhr?)
        store_location_for(:member, request.fullpath)
    end
  end

  def after_sign_in_path_for(resource)
    stored_location_for(:member) || root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    request.referrer
  end

  # tweak CanCan defaults because we don't have a "current_user" method
  # this means that we use current_user in specs but current_member everywhere
  # else in the code.
  def current_ability
    @current_ability ||= Ability.new(current_member)
  end

  # CanCan error handling
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to request.referer || root_url, alert: exception.message
  end

  def set_locale
    I18n.locale = params[:locale] || extract_locale_from_subdomain || I18n.default_locale
  end

  def extract_locale_from_subdomain
    parsed_locale = request.subdomains.first
    I18n.available_locales.map(&:to_s).include?(parsed_locale) ? parsed_locale : nil
  end

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up) do |member|
      member.permit(:login_name, :email, :password, :password_confirmation,
        :remember_me, :login,
        # terms of service
        :tos_agreement,
        # profile stuff
        :bio, :location, :latitude, :longitude,
        # email settings
        :show_email, :newsletter, :send_notification_email, :send_planting_reminder
      )
    end

    devise_parameter_sanitizer.permit(:account_update) do |member|
      member.permit(:login_name, :email, :password, :password_confirmation,
        :remember_me, :login,
        # terms of service
        :tos_agreement,
        # profile stuff
        :bio, :location, :latitude, :longitude,
        # email settings
        :show_email, :newsletter, :send_notification_email, :send_planting_reminder,
        #update password
        :current_password,
        #marking own account as deleted
        :deleted
      )
    end
  end

end
