class UpdatesController < ApplicationController
  # GET /updates
  # GET /updates.json

  def index
    @updates = Update.all
    @recent_updates = Update.limit(100).order('created_at desc').all

    respond_to do |format|
      format.html # index.html.haml
      format.json { render json: @updates }
      format.rss { render :layout => false } #index.rss.builder
    end
  end

  # GET /updates/1
  # GET /updates/1.json
  def show
    @update = Update.find(params[:id])

    respond_to do |format|
      format.html # show.html.haml
      format.json { render json: @update }
    end
  end

  # GET /updates/new
  # GET /updates/new.json
  def new
    @update = Update.new

    respond_to do |format|
      format.html # new.html.haml
      format.json { render json: @update }
    end
  end

  # GET /updates/1/edit
  def edit
    @update = Update.find(params[:id])
  end

  # POST /updates
  # POST /updates.json
  def create
    params[:update][:user_id] = current_user.id
    @update = Update.new(params[:update])

    respond_to do |format|
      if @update.save
        format.html { redirect_to @update, notice: 'Update was successfully created.' }
        format.json { render json: @update, status: :created, location: @update }
      else
        format.html { render action: "new" }
        format.json { render json: @update.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /updates/1
  # PUT /updates/1.json
  def update
    @update = Update.find(params[:id])

    respond_to do |format|
      if @update.update_attributes(params[:update])
        format.html { redirect_to @update, notice: 'Update was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @update.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /updates/1
  # DELETE /updates/1.json
  def destroy
    @update = Update.find(params[:id])
    @update.destroy

    respond_to do |format|
      format.html { redirect_to updates_url }
      format.json { head :no_content }
    end
  end
end
