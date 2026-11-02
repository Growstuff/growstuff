# frozen_string_literal: true

module Admin
  # Merging a duplicate crop into the crop to keep: pick the duplicate by
  # searching, then the crop to keep, then confirm.
  class CropMergesController < ApplicationController
    MATCHES = 20

    before_action :authenticate_member!
    before_action :authorize_admin!

    def show
      @duplicate = Crop.find_by(id: params[:duplicate_id])
      @target = Crop.find_by(id: params[:target_id])
      @target = nil if @target == @duplicate
      @query = params[:q].to_s.squish
      @matches = matching_crops if @query.present? && (@duplicate.nil? || @target.nil?)
      @moves = CropMerger.new(@duplicate, @target, member: current_member).moves if @duplicate && @target
    end

    def create
      duplicate = Crop.find(params[:duplicate_id])
      target = Crop.find(params[:target_id])
      name = duplicate.name
      CropMerger.new(duplicate, target, member: current_member).merge!
      redirect_to crop_path(target), notice: "Merged #{name} into #{target.name}."
    rescue CropMerger::Error => e
      redirect_to admin_crop_merge_path(duplicate_id: params[:duplicate_id], target_id: params[:target_id]), alert: e.message
    end

    private

    def matching_crops
      Crop.matching_name(@query).best_match_first(@query)
        .where.not(id: [@duplicate&.id, @target&.id].compact)
        .includes(:parent)
        .limit(MATCHES)
    end

    def authorize_admin!
      authorize! :wrangle, Crop
    end
  end
end
