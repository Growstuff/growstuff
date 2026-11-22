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
      @records = EcocropData.includes(crops: :alternate_names).order(:scientificname)
      @records = @records.public_send(@filter) if @filter
      @records = @records.search(@query) if @query.present?
      @records = @records.paginate(page: params[:page], per_page: 50)
      @suggestions = EcocropData.suggested_crops(@records)
      @counts = { all: EcocropData.count, matched: EcocropData.matched.count }
    end

    # The records for a name, for the dialog on a crop's page that finds the one to link.
    def search
      records = EcocropData.includes(:crops).best_matches(params[:q])
      render json: records.map { |record|
        { id:              record.id,
          scientific_name: record.scientificname,
          common_names:    record.common_names,
          details:         helpers.ecocrop_details(record),
          crops:           record.crops.map(&:name).first(3) }
      }
    end

    # A crop has one EcoCrop record, so linking it moves it off any record it was linked to before.
    # The names ticked in the dialog are copied to the crop as alternate names.
    def link
      crop = Crop.find(params[:crop_id])
      added = linker.link(crop, names: params[:names])
      redirect_back_or_to admin_ecocrop_data_path, notice: t('.linked', crop: crop.name, record: record.scientificname, count: added)
    rescue ActiveRecord::RecordInvalid
      redirect_back_or_to admin_ecocrop_data_path, alert: t('.failed', crop: crop.name)
    end

    # A new crop from a record with no crop of its own.
    def create_crop
      crop = linker.create_crop(name: params[:name], wikipedia_url: params[:en_wikipedia_url], names: params[:names])
      redirect_back_or_to admin_ecocrop_data_path, notice: t('.created', crop: crop.name, record: record.scientificname)
    rescue EcocropCropLinker::Error => e
      redirect_back_or_to admin_ecocrop_data_path, alert: t(".#{e.message}", name: params[:name])
    rescue ActiveRecord::RecordInvalid => e
      redirect_back_or_to admin_ecocrop_data_path, alert: e.record.errors.full_messages.to_sentence
    end

    def unlink
      crop = record.crops.find(params[:crop_id])
      crop.update(ecocrop_record: nil)
      redirect_back_or_to admin_ecocrop_data_path, notice: t('.unlinked', crop: crop.name, record: record.scientificname)
    end

    private

    def record
      @record ||= EcocropData.find(params[:id])
    end

    def linker
      EcocropCropLinker.new(record:, member: current_member)
    end
  end
end
