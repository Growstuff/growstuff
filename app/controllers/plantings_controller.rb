class PlantingsController < ApplicationController
  load_and_authorize_resource

  cache_sweeper :planting_sweeper

  # GET /plantings
  # GET /plantings.json
  def index
    @owner = Member.find_by_slug(params[:owner])
    if @owner
      @plantings = @owner.plantings.includes(:owner, :crop, :garden).paginate(:page => params[:page])
    else
      @plantings = Planting.includes(:owner, :crop, :garden).paginate(:page => params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @plantings }
      format.rss { render :layout => false } #index.rss.builder
      format.csv do
        if @owner
          @filename = "Growstuff-#{@owner}-Plantings-#{Time.zone.now.to_s(:number)}.csv"
          @plantings = @owner.plantings.includes(:owner, :crop, :garden)
        else
          @filename = "Growstuff-Plantings-#{Time.zone.now.to_s(:number)}.csv"
          @plantings = Planting.includes(:owner, :crop, :garden)
        end
        render :csv => @plantings
      end
    end
  end

  # GET /plantings/1
  # GET /plantings/1.json
  def show
    @planting = Planting.includes(:owner, :crop, :garden, :photos).find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planting }
    end
  end

  # GET /plantings/new
  # GET /plantings/new.json
  def new
    @planting = Planting.new('planted_at' => Date.today)

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
    params[:planting][:owner_id] = current_member.id
    params[:planted_at] = parse_date(params[:planted_at])
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
    params[:planted_at] = parse_date(params[:planted_at])

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
    @garden = @planting.garden
    @planting.destroy

    respond_to do |format|
      format.html { redirect_to @garden }
      format.json { head :no_content }
    end
  end
end
