# frozen_string_literal: true

class ScientificNamesController < ApplicationController
  before_action :authenticate_member!, except: %i(index show gbif_suggest)
  load_and_authorize_resource except: [:gbif_suggest]
  respond_to :html, :json
  responders :flash

  # GET /scientific_names
  # GET /scientific_names.json
  def index
    @scientific_names = ScientificName.all.order(:name)
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

    @scientific_name.save
    respond_with(@scientific_name.crop)
  end

  # PUT /scientific_names/1
  # PUT /scientific_names/1.json
  def update
    @scientific_name.update(scientific_name_params)
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
    species = Gbif::Species

    # Query the GBIF name autocomplete and discover the scientific name.
    # [
    #   {
    #   "key": 2932942,
    #   "nameKey": 1970347,
    #   "kingdom": "Plantae",
    #   "phylum": "Tracheophyta",
    #   "order": "Solanales",
    #   "family": "Solanaceae",
    #   "genus": "Capsicum",
    #   "species": "Capsicum chinense",
    #   "kingdomKey": 6,
    #   "phylumKey": 7707728,
    #   "classKey": 220,
    #   "orderKey": 1176,
    #   "familyKey": 7717,
    #   "genusKey": 2932937,
    #   "speciesKey": 2932942,
    #   "parent": "Capsicum",
    #   "parentKey": 2932937,
    #   "nubKey": 2932942,
    #   "scientificName": "Capsicum chinense Jacq.",
    #   "canonicalName": "Capsicum chinense",
    #   "rank": "SPECIES",
    #   "status": "ACCEPTED",
    #   "synonym": false,
    #   "higherClassificationMap": {
    #   "6": "Plantae",
    #   "220": "Magnoliopsida",
    #   "1176": "Solanales",
    #   "7717": "Solanaceae",
    #   "2932937": "Capsicum",
    #   "7707728": "Tracheophyta"
    #   },
    #   "class": "Magnoliopsida"
    #   },
    #   {
    #   "key": 12079498,
    #   "nameKey": 81778754,
    #   "kingdom": "Plantae",
    #   "phylum": "Tracheophyta",
    #   "order": "Solanales",
    #   "family": "Solanaceae",
    #   "genus": "Capsicum",
    #   "species": "Capsicum chinense",
    #   "kingdomKey": 6,
    #   "phylumKey": 7707728,
    #   "classKey": 220,
    #   "orderKey": 1176,
    #   "familyKey": 7717,
    #   "genusKey": 2932937,
    #   "speciesKey": 2932942,
    #   "parent": "Capsicum",
    #   "parentKey": 2932937,
    #   "nubKey": 12079498,
    #   "scientificName": "Capsicum annuum var. chinense (Jacq.) Alef.",
    #   "canonicalName": "Capsicum annuum chinense",
    #   "rank": "VARIETY",
    #   "status": "SYNONYM",
    #   "synonym": true,
    #   "higherClassificationMap": {
    #   "6": "Plantae",
    #   "220": "Magnoliopsida",
    #   "1176": "Solanales",
    #   "7717": "Solanaceae",
    #   "2932937": "Capsicum",
    #   "2932942": "Capsicum chinense",
    #   "7707728": "Tracheophyta"
    #   },
    #   "class": "Magnoliopsida"
    #   }
    #   ]

    data = species.name_suggest(q: params[:term]).map do |result|
      result["name"] = result["canonicalName"]
      result["id"] = result["nameKey"]

      result
    end

    render json: data
  end

  private

  def scientific_name_params
    params.require(:scientific_name).permit(:crop_id, :name)
  end
end
