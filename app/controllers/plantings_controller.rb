class PlantingsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /plantings
  # GET /plantings.json
  def index
    @owner = Member.find_by(slug: params[:owner]) if params[:owner]
    @crop = Crop.find_by(slug: params[:crop]) if params[:crop]
    @show_all = params[:all] == '1'
    @plantings = plantings

    respond_to do |format|
      format.html { @plantings = @plantings.paginate(page: params[:page]) }
      format.json { render json: @plantings }
      format.rss { render layout: false } # index.rss.builder
      format.csv do
        specifics = (@owner ? "#{@owner.login_name}-" : @crop ? "#{@crop.name}-" : nil)
        @filename = "Growstuff-#{specifics}Plantings-#{Time.zone.now.to_s(:number)}.csv"
        render csv: @plantings
      end
    end
  end

  # GET /plantings/1
  # GET /plantings/1.json
  def show
    @planting = Planting.includes(:owner, :crop, :garden, :photos).friendly.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @planting }
    end
  end

  # GET /plantings/new
  # GET /plantings/new.json
  def new
    @planting = Planting.new('planted_at' => Time.zone.today)

    # using find_by_id here because it returns nil, unlike find
    @crop     = Crop.find_by(id: params[:crop_id])     || Crop.new
    @garden   = Garden.find_by(id: params[:garden_id]) || Garden.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @planting }
    end
  end

  # GET /plantings/1/edit
  def edit
    # the following are needed to display the form but aren't used
    @crop     = Crop.new
    @garden   = Garden.new
  end

  # POST /plantings
  # POST /plantings.json
  def create
    params[:planted_at] = parse_date(params[:planted_at])
    @planting = Planting.new(planting_params)
    @planting.owner = current_member

    respond_to do |format|
      if @planting.save
        @planting.update_attribute(:days_before_maturity,
          update_days_before_maturity(@planting, planting_params[:crop_id]))
        format.html { redirect_to @planting, notice: 'Planting was successfully created.' }
        format.json { render json: @planting, status: :created, location: @planting }
        expire_fragment("homepage_stats")
      else
        format.html { render action: "new" }
        format.json { render json: @planting.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /plantings/1
  # PUT /plantings/1.json
  def update
    params[:planted_at] = parse_date(params[:planted_at])

    respond_to do |format|
      if @planting.update(planting_params)
        @planting.update_attribute(:days_before_maturity,
          update_days_before_maturity(@planting, planting_params[:crop_id]))
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
    @garden = @planting.garden
    @planting.destroy
    expire_fragment("homepage_stats")

    respond_to do |format|
      format.html { redirect_to @garden }
      format.json { head :no_content }
    end
  end

  private

  def planting_params
    params.require(:planting).permit(:crop_id, :description, :garden_id, :planted_at,
      :quantity, :sunniness, :planted_from, :owner_id, :finished,
      :finished_at)
  end

  def update_days_before_maturity(planting, crop_id)
    if planting.finished_at.nil?
      planting.calculate_days_before_maturity(planting, crop_id)
    else
      (planting.finished_at - planting.planted_at).to_i
    end
  end

  def plantings
    @plantings = if @owner
                   @owner.plantings
                 elsif @crop
                   @crop.plantings
                 else
                   Planting
                 end

    @plantings = @plantings.current unless @show_all
    @plantings = @plantings.includes(:owner, :crop, :garden).order(:created_at).paginate(page: params[:page])
    @plantings
  end
end
