class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

  after_filter :store_location

  def store_location
    # store last url - this is needed for post-login redirect to whatever the user last visited.
    if (request.fullpath != new_member_session_path && \
      !request.xhr?) # don't store ajax calls
      session[:previous_url] = request.fullpath
    end
  end

  def after_sign_in_path_for(resource)
    session[:previous_url] || root_path
  end

  # tweak CanCan defaults because we don't have a "current_user" method
  # this means that we use current_user in specs but current_member everywhere
  # else in the code.
  def current_ability
    @current_ability ||= Ability.new(current_member)
  end

  # CanCan error handling
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to request.referer || root_url, :alert => exception.message
  end

end
