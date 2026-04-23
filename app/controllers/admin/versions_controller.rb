# frozen_string_literal: true

module Admin
  class VersionsController < ApplicationController
    before_action :authenticate_member!
    before_action :authorize_admin!

    def revert
      @version = PaperTrail::Version.find(params[:id])
      @object = @version.reify
      if @object.save
        redirect_to admin_crops_path, notice: "Reverted to version from #{@version.created_at.strftime('%B %d, %Y')}"
      else
        redirect_to admin_crops_path, alert: "Could not revert to version from #{@version.created_at.strftime('%B %d, %Y')}. Errors: #{@object.errors.full_messages.to_sentence}"
      end
    end

    private

    def authorize_admin!
      authorize! :wrangle, Crop
    end
  end
end
