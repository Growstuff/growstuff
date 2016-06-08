class ScientificNamesController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /scientific_names
  # GET /scientific_names.json
  def index
    @scientific_names = ScientificName.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @scientific_names }
    end
  end

  # GET /scientific_names/1
  # GET /scientific_names/1.json
  def show
    @scientific_name = ScientificName.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @scientific_name }
    end
  end

  # GET /scientific_names/new
  # GET /scientific_names/new.json
  def new
    @scientific_name = ScientificName.new
    @crop = Crop.find_by_id(params[:crop_id]) || Crop.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @scientific_name }
    end
  end

  # GET /scientific_names/1/edit
  def edit
    @scientific_name = ScientificName.find(params[:id])
  end

  # POST /scientific_names
  # POST /scientific_names.json
  def create
    params[:scientific_name][:creator_id] = current_member.id
    @scientific_name = ScientificName.new(scientific_name_params)

    respond_to do |format|
      if @scientific_name.save
        format.html { redirect_to @scientific_name.crop, notice: 'Scientific name was successfully created.' }
        format.json { render json: @scientific_name, status: :created, location: @scientific_name }
      else
        format.html { render action: "new" }
        format.json { render json: @scientific_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /scientific_names/1
  # PUT /scientific_names/1.json
  def update
    @scientific_name = ScientificName.find(params[:id])

    respond_to do |format|
      if @scientific_name.update(scientific_name_params)
        format.html { redirect_to @scientific_name.crop, notice: 'Scientific name was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @scientific_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scientific_names/1
  # DELETE /scientific_names/1.json
  def destroy
    @scientific_name = ScientificName.find(params[:id])
    @crop = @scientific_name.crop
    @scientific_name.destroy

    respond_to do |format|
      format.html {
        redirect_to @crop, notice: 'Scientific name was successfully deleted.'
      }
      format.json { head :no_content }
    end
  end

  private

  def scientific_name_params
    params.require(:scientific_name).permit(:crop_id, :scientific_name, :creator_id)
  end
end
