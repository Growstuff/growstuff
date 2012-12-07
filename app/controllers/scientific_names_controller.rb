class ScientificNamesController < ApplicationController
  # GET /scientific_names
  # GET /scientific_names.json
  def index
    @scientific_names = ScientificName.all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @scientific_names }
    end
  end

  # GET /scientific_names/1
  # GET /scientific_names/1.json
  def show
    @scientific_name = ScientificName.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @scientific_name }
    end
  end

  # GET /scientific_names/new
  # GET /scientific_names/new.json
  def new
    @scientific_name = ScientificName.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @scientific_name }
    end
  end

  # GET /scientific_names/1/edit
  def edit
    @scientific_name = ScientificName.find(params[:id])
  end

  # POST /scientific_names
  # POST /scientific_names.json
  def create
    @scientific_name = ScientificName.new(params[:scientific_name])

    respond_to do |format|
      if @scientific_name.save
        format.html { redirect_to @scientific_name, notice: 'Scientific name was successfully created.' }
        format.json { render json: @scientific_name, status: :created, location: @scientific_name }
      else
        format.html { render action: "new" }
        format.json { render json: @scientific_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /scientific_names/1
  # PUT /scientific_names/1.json
  def update
    @scientific_name = ScientificName.find(params[:id])

    respond_to do |format|
      if @scientific_name.update_attributes(params[:scientific_name])
        format.html { redirect_to @scientific_name, notice: 'Scientific name was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @scientific_name.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /scientific_names/1
  # DELETE /scientific_names/1.json
  def destroy
    @scientific_name = ScientificName.find(params[:id])
    @scientific_name.destroy

    respond_to do |format|
      format.html { redirect_to scientific_names_url }
      format.json { head :no_content }
    end
  end
end
