class ApplicationController < ActionController::Base
  protect_from_forgery

  include ApplicationHelper

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
