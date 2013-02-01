class ApplicationController < ActionController::Base
  protect_from_forgery
  load_and_authorize_resource

  # tweak CanCan defaults because we don't have a "current_user" method
  def current_ability
    @current_ability ||= Ability.new(current_member)
  end

  # CanCan error handling
   rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_url, :alert => exception.message
  end 

end
