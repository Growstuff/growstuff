# frozen_string_literal: true

# Admins deciding who may upload photos to the Growstuff photo library.
module Admin
  class PhotoLibraryAccessesController < ApplicationController
    before_action :admin!
    before_action :load_access, except: :index

    def index
      @status = PhotoLibraryAccess::STATUSES.include?(params[:status]) ? params[:status] : 'requested'
      @accesses = PhotoLibraryAccess.where(status: @status)
        .includes(:member, :decided_by)
        .order(updated_at: :desc)
        .paginate(page: params[:page])
    end

    def approve
      @access.approve!(current_member, note)
      NotifierMailer.photo_library_access_approved(@access).deliver_now!
      redirect_back_to_queue "#{@access.member.login_name} can now upload photos."
    end

    def refuse
      @access.refuse!(current_member, note)
      redirect_back_to_queue "Refused #{@access.member.login_name}'s request."
    end

    def revoke
      @access.revoke!(current_member, note)
      redirect_back_to_queue "#{@access.member.login_name} can no longer upload photos."
    end

    private

    def admin!
      authorize! :manage, :all
    end

    def load_access
      @access = PhotoLibraryAccess.find(params[:id])
    end

    def note
      params[:note].presence
    end

    def redirect_back_to_queue(notice)
      redirect_to admin_photo_library_accesses_path, notice:
    end
  end
end
