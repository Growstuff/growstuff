class AlternateNamesController < ApplicationController
  before_filter :authenticate_member!, except: [:index, :show]
  load_and_authorize_resource

  # GET /alternate_names
  # GET /alternate_names.json
  def index
    @alternate_names = AlternateName.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @alternate_names }
    end
  end

  # GET /alternate_names/new
  # GET /alternate_names/new.json
  def new
    @alternate_name = AlternateName.new
    @crop = Crop.find_by_id(params[:crop_id]) || Crop.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @alternate_name }
    end
  end

  # GET /alternate_names/1/edit
  def edit
    @alternate_name = AlternateName.find(params[:id])
  end

  # POST /alternate_names
  # POST /alternate_names.json
  def create
    params[:alternate_name][:creator_id] = current_member.id
    @alternate_name = AlternateName.new(alternate_name_params)

    respond_to do |format|
      if @alternate_name.save
        format.html { redirect_to @alternate_name.crop, notice: 'Alternate name was successfully created.' }
        format.json { render json: @alternate_name, status: :created, location: @alternate_name }
      else
        format.html { render action: "new" }
        format.json { render json: @alternate_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /alternate_names/1
  # PUT /alternate_names/1.json
  def update
    @alternate_name = AlternateName.find(params[:id])

    respond_to do |format|
      if @alternate_name.update(alternate_name_params)
        format.html { redirect_to @alternate_name.crop, notice: 'Alternate name was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @alternate_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /alternate_names/1
  # DELETE /alternate_names/1.json
  def destroy
    @alternate_name = AlternateName.find(params[:id])
    @crop = @alternate_name.crop
    @alternate_name.destroy

    respond_to do |format|
      format.html {
        redirect_to @crop, notice: 'Alternate name was successfully deleted.'
      }
      format.json { head :no_content }
    end
  end

  private

  def alternate_name_params
    params.require(:alternate_name).permit(:crop_id, :name, :creator_id)
  end
end
