class CropsController < ApplicationController
  load_and_authorize_resource

  cache_sweeper :crop_sweeper

  # GET /crops
  # GET /crops.json
  def index
    @crops = Crop.includes(:scientific_names, {:plantings => :photos}).paginate(:page => params[:page])

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @crops }
      format.rss { render :layout => false }
    end
  end

  # GET /wrangle
  def wrangle
    @crops = Crop.recent.paginate(:page => params[:page])

    respond_to do |format|
      format.html
    end
  end

  # GET /crops/1
  # GET /crops/1.json
  def show
    @crop = Crop.includes(:scientific_names, {:plantings => :photos}).find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @crop }
    end
  end

  # GET /crops/new
  # GET /crops/new.json
  def new
    @crop = Crop.new

    respond_to do |format|
      format.html # new.html.haml
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
    params[:crop][:creator_id] = current_member.id
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
