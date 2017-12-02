class PlantPartsController < ApplicationController
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def index
    @plant_parts = PlantPart.all.order(:name)
    respond_with(@plant_parts)
  end

  def show
    respond_with(@plant_part)
  end

  def new
    @plant_part = PlantPart.new
    respond_with(@plant_part)
  end

  def edit; end

  def create
    @plant_part = PlantPart.create(plant_part_params)
    respond_with(@plant_part)
  end

  def update
    @plant_part.update(plant_part_params)
    respond_with(@plant_part)
  end

  def destroy
    @plant_part.destroy
    respond_with(@plant_part)
  end

  private

  def plant_part_params
    params.require(:plant_part).permit(:name, :slug)
  end
end
