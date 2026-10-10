# frozen_string_literal: true

module Admin
  class VersionsController < ApplicationController
    before_action :authenticate_member!
    before_action :authorize_admin!

    def revert
      @version = PaperTrail::Version.find(params[:id])
      @object = @version.reify
      if @object.save
        redirect_to admin_crops_path, notice: t('messages.revert_success', date: @version.created_at.strftime('%B %d, %Y'))
      else
        redirect_to admin_crops_path, alert: t('messages.revert_error', date: @version.created_at.strftime('%B %d, %Y'), errors: @object.errors.full_messages.to_sentence)
      end
    end

    private

    def authorize_admin!
      authorize! :wrangle, Crop
    end
  end
end
