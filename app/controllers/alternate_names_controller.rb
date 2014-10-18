class AlternateNamesController < ApplicationController
  load_and_authorize_resource

  # GET /alternate_names/1/edit
  def edit
    @alternate_name = AlternateName.find(params[:id])
  end

  # GET /alternate_names/1
  # GET /alternate_names/1.json
  def show
    @alternate_name = AlternateName.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @alternate_name }
    end
  end

  # GET /alternate_names/new
  # GET /alternate_names/new.json
  def new
    @alternate_name = AlternateName.new
    @crop = Crop.find_by_id(params[:crop_id]) || Crop.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @alternate_name }
    end
  end

  # PUT /alternate_names/1
  # PUT /alternate_names/1.json
  def update
    @alternate_name = AlternateName.find(params[:id])

    respond_to do |format|
      if @alternate_name.update_attributes(params[:alternate_name])
        format.html { redirect_to @alternate_name.crop, notice: 'Alternate name was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @alternate_name.errors, status: :unprocessable_entity }
      end
    end
  end
end
