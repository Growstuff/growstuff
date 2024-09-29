class GardenCollaboratorsController < ApplicationController
  def create
    @garden_collaborator = GardenCollaborator.new(garden_collaborator_params)
    authorize! :create, @garden_collaborator

    @garden_collaborator.save

    respond_with(@garden_collaborator)
  end

  def update
    @garden_collaborator = GardenCollaborator.find(params[:garden_collaborator_id])
    authorize! :update, @garden_collaborator

    @garden_collaborator.update(garden_collaborator_params)

    respond_with(@garden_collaborator)
  end

  def destroy
    @garden_collaborator = GardenCollaborator.find(params[:garden_collaborator_id])

    authorize! :destroy, @garden_collaborator
  end

  def edit
    @garden_collaborator = GardenCollaborator.find(params[:garden_collaborator_id])

    authorize! :update, @garden_collaborator
  
    respond_with(@garden_collaborator)
  end

  def new
    @garden_collaborator = GardenCollaborator.new(garden: Garden.find(params[:garden_id]))
  
    authorize! :create, @garden_collaborator

    respond_with(@garden_collaborator)
  end

  def index
    @garden = Garden.find(params[:garden_id])

    respond_with(@garden)
  end

  def show
    @garden_collaborator = GardenCollaborator.find(params[:garden_collaborator_id])

    respond_with(@garden_collaborator)
  end
end
