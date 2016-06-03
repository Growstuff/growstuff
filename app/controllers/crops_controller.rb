require 'will_paginate/array'

class CropsController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :hierarchy, :search, :show]
  load_and_authorize_resource
  skip_authorize_resource only: [:hierarchy, :search]

  # GET /crops
  # GET /crops.json
  def index
    @sort = params[:sort]
    if @sort == 'alpha'
      # alphabetical order
      @crops = Crop.includes(:scientific_names, {plantings: :photos})
      @paginated_crops = @crops.approved.paginate(page: params[:page])
    else
      # default to sorting by popularity
      @crops = Crop.popular.includes(:scientific_names, {plantings: :photos})
      @paginated_crops = @crops.approved.paginate(page: params[:page])
    end

    respond_to do |format|
      format.html
      format.json { render json: @crops }
      format.rss do
        @crops = Crop.recent.includes(:scientific_names, :creator)
        render rss: @crops
      end
      format.csv do
        @filename = "Growstuff-Crops-#{Time.zone.now.to_s(:number)}.csv"
        @crops = Crop.includes(:scientific_names, :plantings, :seeds, :creator)
        render csv: @crops
      end
    end
  end

  # GET /crops/wrangle
  def wrangle
    @approval_status = params[:approval_status]
    case @approval_status
    when "pending"
      @crops = Crop.pending_approval
    when "rejected"
      @crops = Crop.rejected
    else
      @crops = Crop.recent
    end

    @crops = @crops.paginate(page: params[:page])

    @crop_wranglers = Role.crop_wranglers
    respond_to do |format|
      format.html
    end
  end

  # GET /crops/hierarchy
  def hierarchy
    @crops = Crop.toplevel
    respond_to do |format|
      format.html
    end
  end

  # GET /crops/search
  def search
    @term = params[:term]
    @matches = Crop.search(@term)
    @paginated_matches = @matches.paginate(page: params[:page])

    respond_to do |format|
      format.html
      format.json { render json: @matches }
    end
  end

  # GET /crops/1
  # GET /crops/1.json
  def show
    @crop = Crop.includes(:scientific_names, {plantings: :photos}).find(params[:id])
    @posts = @crop.posts.paginate(page: params[:page])

    respond_to do |format|
      format.html # show.html.haml
      format.json do
        render json: @crop.to_json(include: {
          plantings: { include: { owner: { only: [:id, :login_name, :location, :latitude, :longitude] }}}
        })
      end
    end
  end

  # GET /crops/new
  # GET /crops/new.json
  def new
    @crop = Crop.new
    @crop.alternate_names.build
    @crop.scientific_names.build

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @crop }
    end
  end

  # GET /crops/1/edit
  def edit
    @crop = Crop.find(params[:id])
    @crop.alternate_names.build if @crop.alternate_names.blank?
    @crop.scientific_names.build if @crop.scientific_names.blank?

  end

  # POST /crops
  # POST /crops.json
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

    respond_to do |format|
      if @crop.save
        params[:alt_name].each do |index, value|
        @crop.alternate_names.create(name: value, creator_id: current_member.id)
        end
        params[:sci_name].each do |index, value|
        @crop.scientific_names.create(scientific_name: value, creator_id: current_member.id)
        end
        unless current_member.has_role? :crop_wrangler
          Role.crop_wranglers.each do |w|
            Notifier.new_crop_request(w, @crop).deliver_now!
          end
        end

        format.html { redirect_to @crop, notice: success_msg }
        format.json { render json: @crop, status: :created, location: @crop }
      else
        format.html { render action: "new" }
        format.json { render json: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /crops/1
  # PUT /crops/1.json
  def update
    @crop = Crop.find(params[:id])

    previous_status = @crop.approval_status

    @crop.creator = current_member if previous_status == "pending"

    respond_to do |format|
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
          Notifier.crop_request_approved(requester, @crop).deliver_now! if new_status == "approved"
          Notifier.crop_request_rejected(requester, @crop).deliver_now! if new_status == "rejected"
        end
        format.html { redirect_to @crop, notice: 'Crop was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @crop.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /crops/1
  # DELETE /crops/1.json
  def destroy
    @crop = Crop.find(params[:id])
    @crop.destroy

    respond_to do |format|
      format.html { redirect_to crops_url }
      format.json { head :no_content }
    end
  end

  private

  def crop_params
    params.require(:crop).permit(:en_wikipedia_url, :name, :parent_id, :creator_id, :approval_status, :request_notes, :reason_for_rejection, :rejection_notes, scientific_names_attributes: [:scientific_name, :_destroy, :id])
  end
end
