class ApplicationController < ActionController::Base
  protect_from_forgery

  # tweak CanCan defaults because we don't have a "current_user" method
  def current_ability
    @current_ability ||= AccountAbility.new(current_member)
  end

end
