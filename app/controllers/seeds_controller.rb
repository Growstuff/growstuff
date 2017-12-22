class SeedsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  respond_to :csv, only: :index
  respond_to :rss, only: :index

  # GET /seeds
  # GET /seeds.json
  def index
    @owner = Member.find_by(slug: params[:owner])
    @crop = Crop.find_by(slug: params[:crop])
    @seeds = seeds(owner: @owner, crop: @crop)
    @filename = csv_filename

    respond_with(@seeds)
  end

  # GET /seeds/1
  # GET /seeds/1.json
  def show
    @photos = @seed.photos.includes(:owner).order(created_at: :desc).paginate(page: params[:page])
    respond_with(@seed)
  end

  # GET /seeds/new
  # GET /seeds/new.json
  def new
    @seed = Seed.new

    # using find_by_id here because it returns nil, unlike find
    @crop = Crop.find_or_initialize_by(id: params[:crop_id])
    respond_with(@seed)
  end

  # GET /seeds/1/edit
  def edit; end

  # POST /seeds
  # POST /seeds.json
  def create
    @seed = Seed.new(seed_params)
    @seed.owner = current_member
    flash[:notice] = "Successfully added #{@seed.crop} seed to your stash." if @seed.save
    respond_with(@seed)
  end

  # PUT /seeds/1
  # PUT /seeds/1.json
  def update
    flash[:notice] = 'Seed was successfully updated.' if @seed.update(seed_params)
    respond_with(@seed)
  end

  # DELETE /seeds/1
  # DELETE /seeds/1.json
  def destroy
    @seed.destroy
    respond_with(@seed)
  end

  private

  def seed_params
    params.require(:seed).permit(
      :crop_id, :description, :quantity, :plant_before,
      :days_until_maturity_min, :days_until_maturity_max, :organic, :gmo,
      :heirloom, :tradable_to, :slug
    )
  end

  def seeds(owner: nil, crop: nil)
    if owner
      owner.seeds
    elsif crop
      crop.seeds
    else
      Seed
    end.order(created_at: :desc).includes(:owner, :crop).paginate(page: params[:page])
  end

  def csv_filename
    if @owner
      "Growstuff-#{@owner}-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    else
      "Growstuff-Seeds-#{Time.zone.now.to_s(:number)}.csv"
    end
  end
end
