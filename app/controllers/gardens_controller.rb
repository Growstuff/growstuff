class GardensController < ApplicationController
  # GET /gardens
  # GET /gardens.json
  def index
    @gardens = Garden.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @gardens }
    end
  end

  # GET /gardens/1
  # GET /gardens/1.json
  def show
    @garden = Garden.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @garden }
    end
  end

  # GET /gardens/new
  # GET /gardens/new.json
  def new
    @garden = Garden.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @garden }
    end
  end

  # GET /gardens/1/edit
  def edit
    @garden = Garden.find(params[:id])
  end

  # POST /gardens
  # POST /gardens.json
  def create
    params[:garden][:member_id] = current_member.id
    @garden = Garden.new(params[:garden])

    respond_to do |format|
      if @garden.save
        format.html { redirect_to @garden, notice: 'Garden was successfully created.' }
        format.json { render json: @garden, status: :created, location: @garden }
      else
        format.html { render action: "new" }
        format.json { render json: @garden.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /gardens/1
  # PUT /gardens/1.json
  def update
    @garden = Garden.find(params[:id])

    respond_to do |format|
      if @garden.update_attributes(params[:garden])
        format.html { redirect_to @garden, notice: 'Garden was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @garden.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /gardens/1
  # DELETE /gardens/1.json
  def destroy
    @garden = Garden.find(params[:id])
    @garden.destroy

    respond_to do |format|
      format.html { redirect_to gardens_url }
      format.json { head :no_content }
    end
  end
end
