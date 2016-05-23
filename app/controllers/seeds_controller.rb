class SeedsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /seeds
  # GET /seeds.json
  def index
    @owner = Member.find_by_slug(params[:owner])
    @crop = Crop.find_by_slug(params[:crop])
    if @owner
      @seeds = @owner.seeds.includes(:owner, :crop).paginate(page: params[:page])
    elsif @crop
      @seeds = @crop.seeds.includes(:owner, :crop).paginate(page: params[:page])
    else
      @seeds = Seed.includes(:owner, :crop).paginate(page: params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @seeds }
      format.rss { render layout: false } #index.rss.builder
      format.csv do
        if @owner
          @filename = "Growstuff-#{@owner}-Seeds-#{Time.zone.now.to_s(:number)}.csv"
          @seeds = @owner.seeds.includes(:owner, :crop)
        else
          @filename = "Growstuff-Seeds-#{Time.zone.now.to_s(:number)}.csv"
          @seeds = Seed.includes(:owner, :crop)
        end
        render csv: @seeds
      end
    end
  end

  # GET /seeds/1
  # GET /seeds/1.json
  def show
    @seed = Seed.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @seed }
    end
  end

  # GET /seeds/new
  # GET /seeds/new.json
  def new
    @seed = Seed.new

    # using find_by_id here because it returns nil, unlike find
    @crop     = Crop.find_by_id(params[:crop_id])     || Crop.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @seed }
    end
  end

  # GET /seeds/1/edit
  def edit
    @seed = Seed.find(params[:id])
  end

  # POST /seeds
  # POST /seeds.json
  def create
    params[:seed][:owner_id] = current_member.id
    @seed = Seed.new(seed_params)

    respond_to do |format|
      if @seed.save
        format.html { redirect_to @seed, notice: "Successfully added #{@seed.crop} seed to your stash." }
        format.json { render json: @seed, status: :created, location: @seed }
      else
        format.html { render action: "new" }
        format.json { render json: @seed.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /seeds/1
  # PUT /seeds/1.json
  def update
    @seed = Seed.find(params[:id])

    respond_to do |format|
      if @seed.update(seed_params)
        format.html { redirect_to @seed, notice: 'Seed was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @seed.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /seeds/1
  # DELETE /seeds/1.json
  def destroy
    @seed = Seed.find(params[:id])
    @seed.destroy

    respond_to do |format|
      format.html { redirect_to seeds_url }
      format.json { head :no_content }
    end
  end

  private

  def seed_params
    params.require(:seed).permit(
      :owner_id, :crop_id, :description, :quantity, :plant_before,
      :days_until_maturity_min, :days_until_maturity_max, :organic, :gmo,
      :heirloom, :tradable_to, :slug)
  end
end
