# frozen_string_literal: true

module Admin
  class MembersController < ApplicationController
    before_action :admin!
    load_and_authorize_resource
    respond_to :html
    responders :flash

    def index
      @members = Member.all
      @members = @members.where("login_name ILIKE ?", "%#{search_term}%") unless search_term.nil?
      @members = @members.order(:login_name).paginate(page: params[:page])
    end

    def destroy
      @member = Member.find_by!(slug: params[:slug])
      @member.discard
      redirect_to admin_members_path
    end

    def edit
      @member = Member.find_by!(slug: params[:slug])
    end

    def update
      @member = Member.find_by!(slug: params[:slug])
      @member.update(roles: Role.where(id: params.require(:member).require(:role_ids)))

      respond_with @member, location: admin_members_path
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
