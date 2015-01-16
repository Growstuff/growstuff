class CropsController < ApplicationController
  before_filter :authenticate_member!, :except => [:index, :hierarchy, :search, :show]
  load_and_authorize_resource
  skip_authorize_resource :only => [:hierarchy, :search]

  cache_sweeper :crop_sweeper

  # GET /crops
  # GET /crops.json
  def index
    @sort = params[:sort]
    if @sort == 'alpha'
      # alphabetical order
      @crops = Crop.includes(:scientific_names, {:plantings => :photos}).paginate(:page => params[:page])
    else
      # default to sorting by popularity
      @crops = Crop.popular.includes(:scientific_names, {:plantings => :photos}).paginate(:page => params[:page])
    end

    respond_to do |format|
      format.html
      format.json { render :json => @crops }
      format.rss do
        @crops = Crop.recent.includes(:scientific_names, :creator)
        render :rss => @crops
      end
      format.csv do
        @filename = "Growstuff-Crops-#{Time.zone.now.to_s(:number)}.csv"
        @crops = Crop.includes(:scientific_names, :plantings, :seeds, :creator)
        render :csv => @crops
      end
    end
  end

  # GET /crops/wrangle
  def wrangle
    @crops = Crop.recent.paginate(:page => params[:page])
    @crop_wranglers = Role.crop_wranglers
    respond_to do |format|
      format.html
    end
  end

  # GET /crops/hierarchy
  def hierarchy
    @crops = Crop.toplevel
    respond_to do |format|
      format.html
    end
  end

  # GET /crops/search
  def search
    query = params[:term] || params[:search]
    @all_matches = Crop.search(query)

    if exact_match = Crop.find_by_name(query)
      @all_matches.delete(exact_match)
      @all_matches.unshift(exact_match)
    end

    respond_to do |format|
      format.html
      format.json { 
        render :json => @all_matches
      }
    end
  end

  # GET /crops/1
  # GET /crops/1.json
  def show
    @crop = Crop.includes(:scientific_names, {:plantings => :photos}).find(params[:id])
    @posts = @crop.posts.paginate(:page => params[:page])

    respond_to do |format|
      format.html # show.html.haml
      format.json do
        render :json => @crop.to_json(:include => {
          :plantings => { :include => { :owner => { :only => [:id, :login_name, :location, :latitude, :longitude] }}}
        })
      end
    end
  end

  # GET /crops/new
  # GET /crops/new.json
  def new
    @crop = Crop.new
    3.times do
      @crop.scientific_names.build
    end
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
