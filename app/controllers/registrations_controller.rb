class RegistrationsController < Devise::RegistrationsController
  respond_to :json

  def edit
    @twitter_auth  = current_member.auth('twitter')
    @flickr_auth   = current_member.auth('flickr')
    @facebook_auth = current_member.auth('facebook')
    render "edit"
  end

# we need this subclassed method so that Devise doesn't force people to
# change their password every time they want to edit their settings.
# we also check that they give their current password to change their password.
# Code copied from
# https://github.com/plataformatec/devise/wiki/How-To:-Allow-users-to-edit-their-account-without-providing-a-password

  def update

    @member = Member.find(current_member.id)

    successfully_updated = if needs_password?(@member, params)
      @member.update_with_password(devise_parameter_sanitizer.sanitize(:account_update))
    else
      # remove the virtual current_password attribute
      # update_without_password doesn't know how to ignore it
      params[:member].delete(:current_password)
      @member.update_without_password(devise_parameter_sanitizer.sanitize(:account_update))
    end

    if successfully_updated
      if @member.deleted
        redirect_to root_url, notice: "Member deleted."
      else
        set_flash_message :notice, :updated
        # Sign in the member bypassing validation in case their password changed
        sign_in @member, bypass: true
        redirect_to edit_member_registration_path
      end
    else
      render "edit"
    end

  end
end

# check if we need the current password to update fields
def needs_password?(member, params)
  params[:member][:password].present? ||
  params[:member][:password_confirmation].present? ||
  params[:member][:deleted].present?
end

# marking someone as deleted has various effects
def delete
  @member = Member.find(params[:id])

    # move any of their crops to cropbot
    if Role.crop_wranglers && (Role.crop_wranglers.include? @member)
      cropbot = Member.find_by_login_name('ex_wrangler')
      if Crop.find_by(creator: @member)
        # this is ugly, need to make it more efficient
        Crop.where(creator: @member).each do |crop|
          Crop.update(crop, creator: cropbot)
          crop.save!
        end
      end
    end

    # mark their comments as deleted
    ex_member = Member.find_by_login_name('ex_member')
    if Comment.find_by(author: @member)
      Comment.where(author: @member).each do |comment|
        Comment.update(comment, author: ex_member, body: "This comment was removed as the author deleted their account.")
        comment.save!
      end
    end

    # mark their posts as deleted
    ex_member = Member.find_by_login_name('ex_member')
    if Post.find_by(author: @member)
      Post.where(author: @member).each do |post|
        Post.update(post, author: ex_member, body: "This post was removed as the author deleted their account.")
        post.save!
      end
    end

end
