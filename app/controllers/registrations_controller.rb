
class RegistrationsController < Devise::RegistrationsController

  def edit
    @twitter_auth = current_member.auth('twitter')
    @flickr_auth  = current_member.auth('flickr')
    render "edit"
  end

# we need this subclassed method so that Devise doesn't force people to
# change their password every time they want to edit their settings.
# Code copied from
# https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password

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
      redirect_to edit_member_registration_path
    else
      render "edit"
    end
  end
end
