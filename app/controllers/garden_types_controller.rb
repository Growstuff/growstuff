# frozen_string_literal: true

class GardenTypesController < ApplicationController
  respond_to :html, :json
  load_and_authorize_resource

  # GET /garden_types
  def index
    @garden_types = GardenType.all.paginate(page: params[:page])
    respond_with @garden_types
  end

  # GET /garden_types/1
  def show
    respond_with @garden_type
  end

  # GET /garden_types/new
  def new
    @garden_type = GardenType.new
  end

  # GET /garden_types/1/edit
  def edit; end

  # POST /garden_types
  def create
    @garden_type = GardenType.create(garden_type_params)
    respond_with(@garden_type)
  end

  # PATCH/PUT /garden_types/1
  def update
    @garden_type.update(garden_type_params)
    respond_with @garden_type
  end

  # DELETE /garden_types/1
  def destroy
    @garden_type.destroy
    respond_with @garden_type
  end

  private

  def set_garden_type
    @garden_type = GardenType.find(params[:id])
  end

  def garden_type_params
    params.require(:garden_type).permit(:description, :slug)
  end
end
