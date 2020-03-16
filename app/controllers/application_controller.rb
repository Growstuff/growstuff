# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  after_action :store_location
  before_action :set_locale
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  def store_location
    unless request.path.in?(["/members/sign_in",
                             "/members/sign_up",
                             "/members/password/new",
                             "/members/password/edit",
                             "/members/confirmation",
                             "/members/sign_out"]) || request.xhr?
      store_location_for(:member, request.fullpath) if request.format == :html
    end
  end

  def not_found
    render file: 'app/views/errors/404.html', status: :not_found, layout: false
  end

  def after_sign_in_path_for(_resource)
    stored_location_for(:member) || root_path
  end

  def after_sign_out_path_for(_resource_or_scope)
    request.referer
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
                    :show_email, :newsletter, :send_notification_email, :send_planting_reminder)
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
                    # update password
                    :current_password)
    end
  end

  def expire_homepage
    expire_fragment("homepage_stats")
  end
end
