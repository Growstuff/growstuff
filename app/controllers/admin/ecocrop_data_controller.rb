# frozen_string_literal: true

module Admin
  # Every EcoCrop record, and the crops each has been matched to, so crop wranglers can see which are still unmatched.
  class EcocropDataController < ApplicationController
    FILTERS = %w(matched unmatched).freeze

    before_action :authenticate_member!
    before_action { authorize! :wrangle, Crop }

    def index
      @filter = params[:filter] if FILTERS.include?(params[:filter])
      @query = params[:q].to_s.strip
      @records = EcocropData.includes(:crops).order(:scientificname)
      @records = @records.public_send(@filter) if @filter
      @records = @records.search(@query) if @query.present?
      @records = @records.paginate(page: params[:page], per_page: 50)
      @suggestions = EcocropData.suggested_crops(@records)
      @counts = { all: EcocropData.count, matched: EcocropData.matched.count }
    end

    # A crop has one EcoCrop record, so linking it moves it off any record it was linked to before.
    def link
      record = EcocropData.find(params[:id])
      crop = Crop.find(params[:crop_id])
      if crop.update(ecocrop_record: record)
        redirect_back_or_to admin_ecocrop_data_path, notice: t('.linked', crop: crop.name, record: record.scientificname)
      else
        redirect_back_or_to admin_ecocrop_data_path, alert: t('.failed', crop: crop.name)
      end
    end

    def unlink
      record = EcocropData.find(params[:id])
      crop = record.crops.find(params[:crop_id])
      crop.update(ecocrop_record: nil)
      redirect_back_or_to admin_ecocrop_data_path, notice: t('.unlinked', crop: crop.name, record: record.scientificname)
    end
  end
end
