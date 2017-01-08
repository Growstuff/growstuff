class GardensController < ApplicationController
  before_action :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /gardens
  # GET /gardens.json
  def index
    @owner = Member.find_by(slug: params[:owner])
    @gardens = if @owner
                 @owner.gardens.paginate(page: params[:page])
               else
                 Garden.paginate(page: params[:page])
               end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @gardens }
    end
  end

  # GET /gardens/1
  # GET /gardens/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @garden }
    end
  end

  # GET /gardens/new
  # GET /gardens/new.json
  def new
    @garden = Garden.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @garden }
    end
  end

  # GET /gardens/1/edit
  def edit
  end

  # POST /gardens
  # POST /gardens.json
  def create
    @garden.owner_id = current_member.id

    respond_to do |format|
      if @garden.save
        format.html { redirect_to @garden, notice: 'Garden was successfully created.' }
        format.json { render json: @garden, status: :created, location: @garden }
        expire_fragment("homepage_stats")
      else
        format.html { render action: "new" }
        format.json { render json: @garden.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /gardens/1
  # PUT /gardens/1.json
  def update
    respond_to do |format|
      if @garden.update(garden_params)
        format.html { redirect_to @garden, notice: 'Garden was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @garden.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gardens/1
  # DELETE /gardens/1.json
  def destroy
    @garden.destroy
    expire_fragment("homepage_stats")

    respond_to do |format|
      format.html do
        redirect_to gardens_by_owner_path(owner: @garden.owner), notice: 'Garden was successfully deleted.'
      end
      format.json { head :no_content }
    end
  end

  private

  def garden_params
    params.require(:garden).permit(:name, :slug, :owner_id, :description, :active,
      :location, :latitude, :longitude, :area, :area_unit)
  end
end
