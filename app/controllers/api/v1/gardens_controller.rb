class Api::V1::GardensController < Api::ApiController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  api!
  api :GET, '/gardens/owner/:owner'
  param :page, :number
  param :owner, String
  def index
    @gardens = Garden.paginate(page: params[:page])
    @owner = Member.find_by_slug(params[:owner])
    if @owner
      @gardens = @owner.gardens.paginate(page: params[:page])
    end

    render json: @gardens
  end

  # GET /gardens/1.json
  api!
  param :id, :number, required: true
  def show
    @garden = Garden.find(params[:id])

    format.json { render json: @garden }
  end

  # POST /gardens.json
  api!
  def create
    params[:garden][:owner_id] = current_member.id
    @garden = Garden.new(garden_params)

    if @garden.save
      render json: @garden, status: :created, location: @garden
    else
      render json: @garden.errors, status: :unprocessable_entity
    end
  end

  # PUT /gardens/1.json
  api!
  param :id, :number, required: true
  def update
    @garden = Garden.find(params[:id])

    if @garden.update(garden_params)
      head :no_content
    else
      render json: @garden.errors, status: :unprocessable_entity
    end
  end

  # DELETE /gardens/1.json
  api!
  param :id, :number, required: true
  def destroy
    @garden = Garden.find(params[:id])
    @garden.destroy
    expire_fragment("homepage_stats")

    head :no_content
  end

  private

  def garden_params
    params.require(:garden).permit(:name, :slug, :owner_id, :description, :active,
    :location, :latitude, :longitude, :area, :area_unit)
  end
end
