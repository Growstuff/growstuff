class PasswordsController < Devise::PasswordsController

  protected
  def after_resetting_password_path_for(resource)
    root_path
  end
end
