# frozen_string_literal: true

# How a planting was started: from seed, as a seedling, from a cutting and so on. The planting page asks its owner, and
# answers here.
module Plantings
  class OriginsController < ApplicationController
    before_action :authenticate_member!
    before_action :load_planting

    def update
      crop_before = @planting.crop
      @planting.assign_attributes(origin_params)
      @planting.parent_seed = parent_seed if params[:planting].key?(:parent_seed_id)

      if @planting.save
        # The page offers to undo a change of crop, so it needs to know what the crop was.
        render json: { url: planting_path(@planting, crop_was: (crop_before.id if @planting.saved_change_to_crop_id?)) }
      else
        render json: { errors: @planting.errors.to_hash }, status: :unprocessable_content
      end
    end

    private

    def load_planting
      @planting = Planting.find_by!(slug: params[:planting_slug])
      authorize! :update, @planting
    end

    def origin_params
      params.expect(planting: [:planted_from,
                               { seedling_attributes: %i(source supplier label_text) }])
    end

    # Only one of their own packets, or none to take the link off.
    def parent_seed
      current_member.seeds.find(params[:planting][:parent_seed_id]) if params[:planting][:parent_seed_id].present?
    end
  end
end
