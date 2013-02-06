# we need this subclass so that Devise doesn't force people to change their
# password every time they want to edit their settings. Code copied from
# https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password

class RegistrationsController < Devise::RegistrationsController
  def update
    # required for settings form to submit when password is left blank
    if params[:member][:password].blank?
      params[:member].delete("password")
      params[:member].delete("password_confirmation")
      params[:member].delete("current_password")
    end

    @member = Member.find(current_member.id)
    if @member.update_attributes(params[:member])
      set_flash_message :notice, :updated
      # Sign in the member bypassing validation in case his password changed
      sign_in @member, :bypass => true
      redirect_to after_update_path_for(@member)
    else
      render "edit"
    end
  end
end
