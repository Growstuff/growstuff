class ForumsController < ApplicationController
  load_and_authorize_resource
  respond_to :html, :json

  # GET /forums
  # GET /forums.json
  def index
    @forums = Forum.all.order(:name)
    respond_with(@forums)
  end

  # GET /forums/1
  # GET /forums/1.json
  def show
    respond_with(@forum)
  end

  # GET /forums/new
  # GET /forums/new.json
  def new
    @forum = Forum.new
    respond_with(@forum)
  end

  # GET /forums/1/edit
  def edit; end

  # POST /forums
  # POST /forums.json
  def create
    @forum = Forum.new(forum_params)
    flash[:notice] = 'Forum was successfully created.' if @forum.save
    respond_with(@forum)
  end

  # PUT /forums/1
  # PUT /forums/1.json
  def update
    flash[:notice] = 'Forum was successfully updated.' if @forum.update(forum_params)
    respond_with(@forum)
  end

  # DELETE /forums/1
  # DELETE /forums/1.json
  def destroy
    @forum.destroy
    flash[:notice] = 'Forum was successfully deleted'
    redirect_to forums_url
  end

  private

  def forum_params
    params.require(:forum).permit(:description, :name, :owner_id, :slug)
  end
end
