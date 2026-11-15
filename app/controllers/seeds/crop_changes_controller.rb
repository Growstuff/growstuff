# frozen_string_literal: true

# Asked after a seed's crop is changed: the plantings, harvests and seeds that
# came from it are still of the old crop, so should they change too?
module Seeds
  class CropChangesController < ApplicationController
    before_action :authenticate_member!
    before_action :load_change

    def show
      redirect_to seed_path(@seed) unless @change.any?
    end

    def update
      @change.apply!
      redirect_to seed_path(@seed), notice: t('.changed')
    rescue ActiveRecord::RecordInvalid => e
      redirect_to seed_crop_change_path(@seed, from: @change.from_crop.id), alert: e.message
    end

    private

    def load_change
      @seed = Seed.find_by!(slug: params[:seed_slug])
      authorize! :update, @seed
      @change = SeedCropChange.new(@seed, Crop.find_by(id: params[:from]))
    end
  end
end
