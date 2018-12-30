class ScientificNamesController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  def index
    @scientific_names = ScientificName.all.order(:name).paginate(page: params[:page])
    respond_with(@scientific_names)
  end

  def show
    respond_with(@scientific_name)
  end

  def new
    @crop = Crop.find(params[:crop_id])

    respond_with(@scientific_name)
  end

  def edit; end

  def create
    @scientific_name.creator = current_member
    @scientific_name.save

    respond_with(@scientific_name.crop)
  end

  def update
    @scientific_name.update(scientific_name_params)
    respond_with(@scientific_name.crop)
  end

  def destroy
    @crop = @scientific_name.crop
    @scientific_name.destroy
    flash[:notice] = 'Scientific name was successfully deleted.'
    respond_with(@crop)
  end

  private

  def scientific_name_params
    params.require(:scientific_name).permit(:crop_id, :name)
  end
end
