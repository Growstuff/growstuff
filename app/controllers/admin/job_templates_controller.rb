# frozen_string_literal: true

module Admin
  # Every crop's job templates in one list, for crop wranglers to find the
  # drafts waiting to be checked and published.
  class JobTemplatesController < ApplicationController
    before_action :authenticate_member!
    before_action { authorize! :wrangle, Crop }

    def index
      @status = params[:status] if CropJobTemplate.statuses.key?(params[:status])
      @templates = CropJobTemplate.joins(:crop).includes(:creator, :steps, crop: :parent).order('crops.name', :name)
      @templates = @templates.where(status: @status) if @status
      @templates = @templates.paginate(page: params[:page])
    end
  end
end
