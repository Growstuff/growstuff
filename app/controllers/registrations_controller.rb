# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  respond_to :json

  prepend_before_action :check_captcha, only: [:create] # Change this to be any actions you want to protect with recaptcha.

  def edit
    @twitter_auth  = current_member.auth('twitter')
    @flickr_auth   = current_member.auth('flickr')
    render "edit"
  end

  # we need this subclassed method so that Devise doesn't force people to
  # change their password every time they want to edit their settings.
  # we also check that they give their current password to change their password.
  # Code copied from
  # https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password

  def update
    @member = Member.find(current_member.id)

    if needs_password?(@member, params)
      successfully_updated = @member.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
    else
      # remove the virtual current_password attribute
      # update_without_password doesn't know how to ignore it
      params[:member].delete(:current_password)
      successfully_updated = @member.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
    end

    if successfully_updated
      set_flash_message :notice, :updated
      # Sign in the member bypassing validation in case their password changed
      sign_in @member, bypass: true
      redirect_to edit_member_registration_path
    else
      render "edit"
    end
  end

  def destroy
    if @member.valid_password?(params.require(:member)[:current_password])
      @member.discard
      redirect_to root_path
    else
      @member.errors.add(:current_password, 'Incorrect password')
      render "edit"
    end
  end

  private

  def sign_up_params
    params.require(:member).permit(:login_name, :email, :tos_agreement, :newsletter, :password, :password_confirmation)
  end

  def check_captcha
    return if verify_recaptcha # verify_recaptcha(action: 'signup') for v3

    self.resource = resource_class.new sign_up_params
    resource.validate # Look for any other validation errors besides reCAPTCHA
    set_minimum_password_length

    respond_with_navigational(resource) do
      flash.discard(:recaptcha_error) # We need to discard flash to avoid showing it on the next page reload
      render :new
    end
  end
end

# check if we need the current password to update fields
def needs_password?(_member, params)
  params[:member][:password].present? ||
    params[:member][:password_confirmation].present?
end
