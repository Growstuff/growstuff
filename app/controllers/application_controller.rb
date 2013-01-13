class ApplicationController < ActionController::Base
  protect_from_forgery

  def current_user
    @current_user ||= Member.find(session[:member_id])
  end
end
