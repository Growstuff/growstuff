require 'will_paginate/array'
class Api::V1::CropsController < ApplicationController

  before_filter :authenticate_member!, except: [:index, :search, :show]
  load_and_authorize_resource
  skip_authorize_resource only: [:search]

  # GET /crops.json
  api!
  def index
    # default to sorting by popularity
    @crops = Crop.popular.includes(:scientific_names, {plantings: :photos})
    @paginated_crops = @crops.approved.paginate(page: params[:page])

    render json: @paginated_crops
  end


  # GET /crops/search
  api!
  def search
    @term = params[:term]
    @matches = Crop.search(@term)
    @paginated_matches = @matches.paginate(page: params[:page])

    render json: @matches
  end

  # GET /crops/1.json
  api!
  def show
    @crop = Crop.includes(:scientific_names, {plantings: :photos}).find(params[:id])
    @posts = @crop.posts.paginate(page: params[:page])

    # TODO RABL or similar one day to avoid presentation logic here
    owner_structure = {
      owner: {
        only: [:id, :login_name, :location, :latitude, :longitude] 
      }
    }

    render json: @crop.to_json(include: {
      plantings: {
        include: owner_structure
      }
    })
  end

  # POST /crops.json
  api!
  def create

    @crop = Crop.new(crop_params)

    if current_member.has_role? :crop_wrangler
      @crop.creator = current_member
      success_msg = "Crop was successfully created."
    else
      @crop.requester = current_member
      @crop.approval_status = "pending"
      success_msg = "Crop was successfully requested."
    end

    if @crop.save
      params[:alt_name].each do |index, value|
        @crop.alternate_names.create(name: value, creator_id: current_member.id)
      end
      params[:sci_name].each do |index, value|
        @crop.scientific_names.create(scientific_name: value, creator_id: current_member.id)
      end
      unless current_member.has_role? :crop_wrangler
        Role.crop_wranglers.each do |w|
          Notifier.new_crop_request(w, @crop).deliver_later!
        end
      end

      render json: @crop, status: :created, location: @crop
    else
      render json: @crop.errors, status: :unprocessable_entity
    end
  end

  # PUT /crops/1.json
  api!
  def update
    @crop = Crop.find(params[:id])

    previous_status = @crop.approval_status

    @crop.creator = current_member if previous_status == "pending"

    if @crop.update(crop_params)
      if !params[:alt_name].nil?
        @crop.alternate_names.each do |alt_name|
          alt_name.destroy
        end

        params[:alt_name].each do |index, value|
          alt_name = @crop.alternate_names.create(name: value, creator_id: current_member.id)
        end

        @crop.scientific_names.each do |sci_name|
          sci_name.destroy
        end
        params[:sci_name].each do |index, value|
          sci_name = @crop.scientific_names.create(scientific_name: value, creator_id: current_member.id)
        end
      end
      
      if previous_status == "pending"
        requester = @crop.requester
        new_status = @crop.approval_status
        Notifier.crop_request_approved(requester, @crop).deliver_later! if new_status == "approved"
        Notifier.crop_request_rejected(requester, @crop).deliver_later! if new_status == "rejected"
      end
      head :no_content
    else
      render json: @crop.errors, status: :unprocessable_entity
    end
  end

  # DELETE /crops/1.json
  api!
  def destroy
    @crop = Crop.find(params[:id])
    @crop.destroy

    head :no_content
  end

  private

  def crop_params
    params.require(:crop).permit(:en_wikipedia_url, :name, :parent_id, :creator_id, :approval_status, :request_notes, :reason_for_rejection, :rejection_notes, scientific_names_attributes: [:scientific_name, :_destroy, :id])
  end
end
