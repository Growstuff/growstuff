class ApplicationController < ActionController::Base
  protect_from_forgery

  # tweak CanCan defaults because we don't have a "current_user" method
  def current_ability
    @current_ability ||= Ability.new(current_member)
  end

  # CanCan error handling
   rescue_from CanCan::AccessDenied do |exception|
    redirect_to request.referer || root_url, :alert => exception.message
  end 

end
