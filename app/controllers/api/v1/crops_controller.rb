class Api::V1::CropsController < ApplicationController

  # GET /api/v1/crops
  def index
    @crops = Crop.all
  end

  # GET /crops/1
  def show
    @crop = Crop.find(params[:id])
  end

end
