# frozen_string_literal: true

# A member asking to upload photos to the Growstuff photo library.
class PhotoLibraryAccessesController < ApplicationController
  before_action :authenticate_member!

  def create
    authorize! :create, PhotoLibraryAccess.new(member: current_member)
    access = PhotoLibraryAccess.request!(current_member, params.dig(:photo_library_access, :request_message))
    notify_admins(access) if access.newly_requested?
    redirect_to "#{edit_member_registration_path}#photos", notice: notice_for(access)
  end

  private

  def notify_admins(access)
    Role.admins&.each do |admin|
      NotifierMailer.new_photo_library_request(admin, access).deliver_now!
    end
  end

  def notice_for(access)
    if access.approved?
      "You can already upload photos."
    else
      "Thanks! An admin will look at your request."
    end
  end
end
