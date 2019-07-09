class GardensController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  after_action :expire_homepage, only: %i(create destroy)
  load_and_authorize_resource
  responders :flash
  respond_to :html, :json

  # GET /gardens
  # GET /gardens.json
  def index
    @owner = Member.find_by(slug: params[:member_slug])
    @show_all = params[:all] == '1'

    @gardens = @gardens.active unless @show_all
    @gardens = @gardens.where(owner: @owner) if @owner.present?
    @gardens = @gardens.joins(:owner).order(:name).paginate(page: params[:page])
    @gardens = @gardens.includes(:owner, plantings: [:owner, crop: :parent])
    respond_with(@gardens)
  end

  # GET /gardens/1
  # GET /gardens/1.json
  def show
    @current_plantings = @garden.plantings.current
      .includes(:crop, :owner)
      .order(planted_at: :desc)
    @finished_plantings = @garden.plantings.finished
      .includes(:crop)
      .order(finished_at: :desc)
    respond_with(@garden)
  end

  # GET /gardens/new
  # GET /gardens/new.json
  def new
    @garden = Garden.new
    respond_with(@garden)
  end

  # GET /gardens/1/edit
  def edit
    respond_with(@garden)
  end

  # POST /gardens
  # POST /gardens.json
  def create
    @garden.owner_id = current_member.id
    flash[:notice] = I18n.t('gardens.created') if @garden.save
    respond_with(@garden)
  end

  # PUT /gardens/1
  # PUT /gardens/1.json
  def update
    flash[:notice] = I18n.t('gardens.updated') if @garden.update(garden_params)
    respond_with(@garden)
  end

  # DELETE /gardens/1
  # DELETE /gardens/1.json
  def destroy
    @garden.destroy
    flash[:notice] = I18n.t('gardens.deleted')
    redirect_to(member_gardens_path(@garden.owner))
  end

  private

  def garden_params
    params.require(:garden).permit(:name, :slug, :description, :active,
      :location, :latitude, :longitude, :area, :area_unit, :garden_type_id)
  end
end
