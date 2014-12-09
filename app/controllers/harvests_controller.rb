class HarvestsController < ApplicationController

  load_and_authorize_resource
  before_filter :authenticate_member!, :except => [:index, :show]

  # GET /harvests
  # GET /harvests.json
  def index
    @owner = Member.find_by_slug(params[:owner])
    @crop = Crop.find_by_slug(params[:crop])
    if @owner
      @harvests = @owner.harvests.includes(:owner, :crop)
    elsif @crop
      @harvests = @crop.harvests.includes(:owner, :crop)
    else
      @harvests = Harvest.includes(:owner, :crop)
    end

    respond_to do |format|
      format.html { @harvests = @harvests.paginate(:page => params[:page]) }
      format.json { render json: @harvests }
      format.csv do
        specifics = (@owner ? "#{@owner.name}-" : @crop ? "#{@crop.name}-" : nil)
        @filename = "Growstuff-#{specifics}Harvests-#{Time.zone.now.to_s(:number)}.csv"
        render :csv => @harvests
      end
    end
  end

  # GET /harvests/1
  # GET /harvests/1.json
  def show
    @harvest = Harvest.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @harvest }
    end
  end

  # GET /harvests/new
  # GET /harvests/new.json
  def new
    @harvest = Harvest.new('harvested_at' => Date.today)

    # using find_by_id here because it returns nil, unlike find
    @crop     = Crop.find_by_id(params[:crop_id]) || Crop.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @harvest }
    end
  end

  # GET /harvests/1/edit
  def edit
    @harvest = Harvest.find(params[:id])
  end

  # POST /harvests
  # POST /harvests.json
  def create
    params[:harvest][:owner_id] = current_member.id
    params[:harvested_at] = parse_date(params[:harvested_at])
    @harvest = Harvest.new(params[:harvest])

    respond_to do |format|
      if @harvest.save
        format.html { redirect_to @harvest, notice: 'Harvest was successfully created.' }
        format.json { render json: @harvest, status: :created, location: @harvest }
      else
        format.html { render action: "new" }
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /harvests/1
  # PUT /harvests/1.json
  def update
    @harvest = Harvest.find(params[:id])

    respond_to do |format|
      if @harvest.update_attributes(params[:harvest])
        format.html { redirect_to @harvest, notice: 'Harvest was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @harvest.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /harvests/1
  # DELETE /harvests/1.json
  def destroy
    @harvest = Harvest.find(params[:id])
    @harvest.destroy

    respond_to do |format|
      format.html { redirect_to harvests_url }
      format.json { head :no_content }
    end
  end
end
