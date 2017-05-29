class PlantingsController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  after_action :expire_homepage, only: [:create, :update, :destroy]
  load_and_authorize_resource

  respond_to :html, :json
  respond_to :csv, :rss, only: [:index]
  responders :flash

  def index
    @owner = Member.find_by(slug: params[:owner]) if params[:owner]
    @crop = Crop.find_by(slug: params[:crop]) if params[:crop]
    @show_all = params[:all] == '1'

    @plantings = plantings

    specifics = if @owner
                  "#{@owner.login_name}-"
                elsif @crop
                  "#{@crop.name}-"
                end

    @filename = "Growstuff-#{specifics}Plantings-#{Time.zone.now.to_s(:number)}.csv"

    respond_with(@plantings)
  end

  def show
    @planting = Planting.includes(:owner, :crop, :garden, :photos)
      .friendly
      .find(params[:id])
    respond_with @planting
  end

  def new
    @planting = Planting.new(planted_at: Time.zone.today)

    # using find_by_id here because it returns nil, unlike find
    @crop     = Crop.approved.find_by(id: params[:crop_id]) || Crop.new
    @garden   = Garden.find_by(owner: current_member, id: params[:garden_id]) || Garden.new

    respond_with @planting
  end

  def edit
    # the following are needed to display the form but aren't used
    @crop     = Crop.new
    @garden   = Garden.new
  end

  def create
    @planting = Planting.new(planting_params)
    @planting.owner = current_member
    @planting.calc_and_set_days_before_maturity
    @planting.save
    respond_with @planting
  end

  def update
    @planting.calc_and_set_days_before_maturity
    @planting.update(planting_params)
    respond_with @planting
  end

  def destroy
    @planting.destroy
    respond_with @planting, location: garden
  end

  private

  def planting_params
    params[:planted_at] = parse_date(params[:planted_at]) if params[:planted_at]
    params.require(:planting).permit(
      :crop_id, :description, :garden_id, :planted_at,
      :quantity, :sunniness, :planted_from, :finished,
      :finished_at
    )
  end

  def plantings
    p = if @owner
          @owner.plantings
        elsif @crop
          @crop.plantings
        else
          Planting
        end
    p = p.current unless @show_all
    p.joins(:owner, :crop, :garden).order(:created_at).paginate(page: params[:page])
  end
end
