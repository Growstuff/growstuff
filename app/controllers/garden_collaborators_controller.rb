class GardenCollaboratorsController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  before_action :load_garden
  load_and_authorize_resource id_param: :slug

  respond_to :html
  responders :flash

  def index
    @garden_collaborators = @garden.garden_collaborators.paginate(page: params[:page])
    respond_with(@garden_collaborators)
  end

  def show
    @garden_collaborator = GardenCollaborator.find(params[:garden_collaborator_id])

    respond_with(@garden_collaborator)
  end

  def new
    @garden_collaborator = GardenCollaborator.new(garden: @garden)

    authorize! :create, @garden_collaborator

    respond_with(@garden_collaborator)
  end

  def edit
    @garden_collaborator = GardenCollaborator.find(params[:id])

    authorize! :update, @garden_collaborator

    respond_with(@garden_collaborator)
  end

  def create
    @garden_collaborator = GardenCollaborator.new(garden: @garden)
    authorize! :create, @garden_collaborator

    @member = Member.find_by(slug: params[:garden_collaborator][:member_slug])

    @garden_collaborator.member = @member
    if @garden_collaborator.save
      redirect_to garden_garden_collaborators_path(@garden)
    else
      respond_with(@garden_collaborator)
    end
  end

  def update
    @garden_collaborator = GardenCollaborator.find(params[:id])
    authorize! :update, @garden_collaborator

    @member = Member.find_by(slug: params[:garden_collaborator][:member_slug])

    @garden_collaborator.member = @member
    @garden_collaborator.save

    respond_with(@garden_collaborator)
  end

  def destroy
    @garden_collaborator = GardenCollaborator.find(params[:id])

    authorize! :destroy, @garden_collaborator

    if @garden_collaborator.destroy
      redirect_to garden_garden_collaborators_path(@garden)
    else
      respond_with(@garden_collaborator)
    end
  end

  private

  def load_garden
    @garden = Garden.find_by(slug: params[:garden_slug])
  end

  def garden_collaborator_params
    params.require(:garden_collaborator).permit(
      :member_slug
    )
  end
end
