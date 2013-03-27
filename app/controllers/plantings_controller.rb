class PlantingsController < ApplicationController
  load_and_authorize_resource
  # GET /plantings
  # GET /plantings.json
  def index
    @plantings = Planting.all
    @recent_plantings = Planting.limit(100).order('created_at desc').all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @plantings }
      format.rss { render :layout => false } #index.rss.builder

    end
  end

  # GET /plantings/1
  # GET /plantings/1.json
  def show
    @planting = Planting.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planting }
    end
  end

  # GET /plantings/new
  # GET /plantings/new.json
  def new
    @planting = Planting.new
    @planting.planted_at = Date.today

    # using find_by_id here because it returns nil, unlike find
    @crop     = Crop.find_by_id(params[:crop_id])     || Crop.new
    @garden   = Garden.find_by_id(params[:garden_id]) || Garden.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @planting }
    end
  end

  # GET /plantings/1/edit
  def edit
    @planting = Planting.find(params[:id])
    # the following are needed to display the form but aren't used
    @crop     = Crop.new
    @garden   = Garden.new
  end

  # POST /plantings
  # POST /plantings.json
  def create
    @planting = Planting.new(params[:planting])

    respond_to do |format|
      if @planting.save
        format.html { redirect_to @planting, notice: 'Planting was successfully created.' }
        format.json { render json: @planting, status: :created, location: @planting }
      else
        format.html { render action: "new" }
        format.json { render json: @planting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /plantings/1
  # PUT /plantings/1.json
  def update
    @planting = Planting.find(params[:id])

    respond_to do |format|
      if @planting.update_attributes(params[:planting])
        format.html { redirect_to @planting, notice: 'Planting was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @planting.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /plantings/1
  # DELETE /plantings/1.json
  def destroy
    @planting = Planting.find(params[:id])
    @planting.destroy

    respond_to do |format|
      format.html { redirect_to plantings_url }
      format.json { head :no_content }
    end
  end
end
