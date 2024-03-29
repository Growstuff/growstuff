# frozen_string_literal: true

class ScientificNamesController < ApplicationController
  before_action :authenticate_member!, except: %i(index show gbif_suggest)
  load_and_authorize_resource except: [:gbif_suggest]
  respond_to :html, :json
  responders :flash

  # GET /scientific_names
  # GET /scientific_names.json
  def index
    @scientific_names = ScientificName.all.order(:name).paginate(page: params[:page], per_page: 100)
    respond_with(@scientific_names)
  end

  # GET /scientific_names/1
  # GET /scientific_names/1.json
  def show
    respond_with(@scientific_name)
  end

  # GET /scientific_names/new
  # GET /scientific_names/new.json
  def new
    @scientific_name = ScientificName.new
    @crop = Crop.find_or_initialize_by(id: params[:crop_id])
    respond_with(@scientific_name)
  end

  # GET /scientific_names/1/edit
  def edit; end

  # POST /scientific_names
  # POST /scientific_names.json
  def create
    @scientific_name = ScientificName.new(scientific_name_params)
    @scientific_name.creator = current_member
    gbif_sync!(@scientific_name)
    @scientific_name.save
    respond_with(@scientific_name.crop)
  end

  # PUT /scientific_names/1
  # PUT /scientific_names/1.json
  def update
    @scientific_name.assign_attributes(scientific_name_params)
    gbif_sync!(@scientific_name)
    @scientific_name.save
    respond_with(@scientific_name.crop)
  end

  # DELETE /scientific_names/1
  # DELETE /scientific_names/1.json
  def destroy
    @crop = @scientific_name.crop
    @scientific_name.destroy
    flash[:notice] = 'Scientific name was successfully deleted.'
    respond_with(@crop)
  end

  def gbif_suggest
    render json: gbif_service.suggest(params[:term])
  end

  private

  def gbif_sync!(model)
    return unless model.gbif_key

    result = gbif_service.fetch(model.gbif_key)

    model.gbif_rank = result["rank"]
    model.gbif_status = result["status"]
  end

  def scientific_name_params
    params.require(:scientific_name).permit(:crop_id, :name, :gbif_key)
  end

  def gbif_service
    GbifService.new
  end
end
