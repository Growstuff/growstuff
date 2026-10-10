# frozen_string_literal: true

module Admin
  class CropCompanionsController < AdminController
    before_action :set_crop

    def index
      @crop_companions = @crop.crop_companions
    end

    def new
      @crop_companion = @crop.crop_companions.new
    end

    def create
      @crop_companion = @crop.crop_companions.new(crop_companion_params)
      if @crop_companion.save
        redirect_to admin_crop_crop_companions_path(@crop), notice: t('crop_companions.created')
      else
        render :new
      end
    end

    def destroy
      @crop_companion = @crop.crop_companions.find(params[:id])
      @crop_companion.destroy
      redirect_to admin_crop_crop_companions_path(@crop), notice: t('crop_companions.deleted')
    end

    private

    def set_crop
      @crop = Crop.find_by!(slug: params[:crop_slug])
    end

    def crop_companion_params
      params.require(:crop_companion).permit(:crop_b_id, :source_url)
    end
  end
end
