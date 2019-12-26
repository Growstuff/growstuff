# frozen_string_literal: true

module Admin
  class RolesController < ApplicationController
    before_action :admin!
    load_and_authorize_resource
    respond_to :html
    responders :flash

    def index
      @roles = Role.all.order(:name)
      respond_with @roles
    end

    def new
      @role = Role.new
      respond_with @role
    end

    def edit
      respond_with @role
    end

    def create
      @role = Role.create(role_params)
      respond_with @role, location: admin_roles_path
    end

    def update
      @role.update(role_params)
      respond_with @role, location: admin_roles_path
    end

    def destroy
      @role.destroy
      respond_with @role, location: admin_roles_path
    end

    private

    def admin!
      authorize! :manage, :all
    end

    def role_params
      params.require(:role).permit(:description, :name, :members, :slug)
    end
  end
end
