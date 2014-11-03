class Api::V1::CropsController < ApplicationController
  respond_to :json

  # GET /api/v1/crops
  def index
    @sort = params[:sort]
    if @sort == 'alpha'
      # alphabetical order
      @crops = Crop.includes(:scientific_names, {:plantings => :photos}).paginate(:page => params[:page])
    else
      # default to sorting by popularity
      @crops = Crop.popular.includes(:scientific_names, {:plantings => :photos}).paginate(:page => params[:page])
    end
  end

  # GET /crops/1
  def show
    @crop = Crop.includes(:scientific_names, {:plantings => :photos}).find(params[:id])
    # @posts = @crop.posts.paginate(:page => params[:page])
  end
end
