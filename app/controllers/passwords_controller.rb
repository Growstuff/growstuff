# frozen_string_literal: true

class PasswordsController < Devise::PasswordsController
  protected

  def after_resetting_password_path_for(_resource)
    root_path
  end
end
