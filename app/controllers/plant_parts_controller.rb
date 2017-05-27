class PlantPartsController < ApplicationController
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  # GET /plant_parts
  # GET /plant_parts.json
  def index
    @plant_parts = PlantPart.all
    respond_with(@plant_parts)
  end

  # GET /plant_parts/1
  # GET /plant_parts/1.json
  def show
    respond_with(@plant_part)
  end

  # GET /plant_parts/new
  # GET /plant_parts/new.json
  def new
    @plant_part = PlantPart.new
    respond_with(@plant_part)
  end

  # GET /plant_parts/1/edit
  def edit; end

  # POST /plant_parts
  # POST /plant_parts.json
  def create
    @plant_part = PlantPart.new(plant_part_params)
    @plant_part.save
    respond_with(@plant_part)
  end

  # PUT /plant_parts/1
  # PUT /plant_parts/1.json
  def update
    @plant_part.update(plant_part_params)
    respond_with(@plant_part)
  end

  # DELETE /plant_parts/1
  # DELETE /plant_parts/1.json
  def destroy
    @plant_part.destroy
    respond_with(@plant_part)
  end

  private

  def plant_part_params
    params.require(:plant_part).permit(:name, :slug)
  end
end
