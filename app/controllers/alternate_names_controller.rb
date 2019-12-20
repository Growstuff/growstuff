# frozen_string_literal: true

class AlternateNamesController < ApplicationController
  before_action :authenticate_member!, except: %i(index)
  load_and_authorize_resource
  respond_to :html, :json
  responders :flash

  # GET /alternate_names
  # GET /alternate_names.json
  def index
    @alternate_names = AlternateName.all.order(:name)
    respond_with(@alternate_names)
  end

  # GET /alternate_names/new
  # GET /alternate_names/new.json
  def new
    @alternate_name = AlternateName.new
    @crop = Crop.find_or_initialize_by(id: params[:crop_id])
  end

  # GET /alternate_names/1/edit
  def edit; end

  # POST /alternate_names
  # POST /alternate_names.json
  def create
    params[:alternate_name][:creator_id] = current_member.id
    @alternate_name = AlternateName.new(alternate_name_params)

    if @alternate_name.save
      redirect_to @alternate_name.crop, notice: 'Alternate name was successfully created.'
    else
      render action: "new"
    end
  end

  # PUT /alternate_names/1
  # PUT /alternate_names/1.json
  def update
    if @alternate_name.update(alternate_name_params)
      redirect_to @alternate_name.crop, notice: 'Alternate name was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /alternate_names/1
  # DELETE /alternate_names/1.json
  def destroy
    @crop = @alternate_name.crop
    @alternate_name.destroy
    redirect_to @crop, notice: 'Alternate name was successfully deleted.'
  end

  private

  def alternate_name_params
    params.require(:alternate_name).permit(:crop_id, :name, :creator_id)
  end
end
