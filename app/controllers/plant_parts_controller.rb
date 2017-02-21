class PlantPartsController < ApplicationController
  load_and_authorize_resource
  respond_to :html, :json

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
  def edit
  end

  # POST /plant_parts
  # POST /plant_parts.json
  def create
    @plant_part = PlantPart.new(plant_part_params)

    respond_to do |format|
      if @plant_part.save
        format.html { redirect_to @plant_part, notice: 'Plant part was successfully created.' }
        format.json { render json: @plant_part, status: :created, location: @plant_part }
      else
        format.html { render action: "new" }
        format.json { render json: @plant_part.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /plant_parts/1
  # PUT /plant_parts/1.json
  def update
    respond_to do |format|
      if @plant_part.update(plant_part_params)
        format.html { redirect_to @plant_part, notice: 'Plant part was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @plant_part.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plant_parts/1
  # DELETE /plant_parts/1.json
  def destroy
    @plant_part.destroy

    respond_to do |format|
      format.html { redirect_to plant_parts_url }
      format.json { head :no_content }
    end
  end

  private

  def plant_part_params
    params.require(:plant_part).permit(:name, :slug)
  end
end
