class CropsController < ApplicationController
  # GET /crops
  # GET /crops.json
  def index
    @crops = Crop.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @crops }
    end
  end

  # GET /crops/1
  # GET /crops/1.json
  def show
    @crop = Crop.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @crop }
    end
  end

  # GET /crops/new
  # GET /crops/new.json
  def new
    @crop = Crop.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @crop }
    end
  end

  # GET /crops/1/edit
  def edit
    @crop = Crop.find(params[:id])
  end

  # POST /crops
  # POST /crops.json
  def create
    @crop = Crop.new(params[:crop])

    respond_to do |format|
      if @crop.save
        format.html { redirect_to @crop, notice: 'Crop was successfully created.' }
        format.json { render json: @crop, status: :created, location: @crop }
      else
        format.html { render action: "new" }
        format.json { render json: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /crops/1
  # PUT /crops/1.json
  def update
    @crop = Crop.find(params[:id])

    respond_to do |format|
      if @crop.update_attributes(params[:crop])
        format.html { redirect_to @crop, notice: 'Crop was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crops/1
  # DELETE /crops/1.json
  def destroy
    @crop = Crop.find(params[:id])
    @crop.destroy

    respond_to do |format|
      format.html { redirect_to crops_url }
      format.json { head :no_content }
    end
  end
end
