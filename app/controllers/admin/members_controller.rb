# frozen_string_literal: true

module Admin
  class MembersController < ApplicationController
    before_action :admin!
    load_and_authorize_resource
    respond_to :html
    responders :flash

    def index
      @status = params[:status] == 'deactivated' ? 'deactivated' : 'active'
      @members = @status == 'deactivated' ? Member.discarded : Member.kept
      @members = @members.includes(:roles).order(:login_name)
      @members = @members.where("login_name ILIKE ? OR email ILIKE ?", "%#{search_term}%", "%#{search_term}%") if search_term.present?
      @members = @members.paginate(page: params[:page])
    end

    def edit
      @member = Member.find_by!(slug: params[:slug])
    end

    def update
      @member = Member.find_by!(slug: params[:slug])
      @member.update(roles: Role.where(id: params.require(:member).require(:role_ids)))

      respond_with @member, location: admin_members_path
    end

    def destroy
      @member = Member.find_by!(slug: params[:slug])
      @member.discard
      redirect_to admin_members_path(status: params[:status])
    end

    def restore
      @member = Member.find_by!(slug: params[:slug])
      @member.undiscard
      redirect_to admin_members_path(status: 'deactivated')
    end

    def bulk_ban
      member_ids = params[:member_ids]
      if member_ids.present? && member_ids.is_a?(Array)
        members_to_ban = Member.kept.where(id: member_ids)
        # Prevent admins from self-banning via bulk ban
        members_to_ban = members_to_ban.where.not(id: current_member.id)
        members_to_ban.find_each(&:discard)
        flash[:notice] = "Selected members have been banned."
      else
        flash[:alert] = "No members were selected."
      end
      redirect_to admin_members_path
    end

    private

    def search_term
      params[:q]
    end

    def admin!
      authorize! :manage, :all
    end
  end
end
