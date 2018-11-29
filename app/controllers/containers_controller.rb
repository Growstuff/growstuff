class ContainersController < ApplicationController
  before_action :set_container, only: [:show, :edit, :update, :destroy]

  # GET /containers
  def index
    @containers = Container.all
  end

  # GET /containers/1
  def show
  end

  # GET /containers/new
  def new
    @container = Container.new
  end

  # GET /containers/1/edit
  def edit
  end

  # POST /containers
  def create
    @container = Container.new(container_params)

    if @container.save
      redirect_to @container, notice: 'Container was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /containers/1
  def update
    if @container.update(container_params)
      redirect_to @container, notice: 'Container was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /containers/1
  def destroy
    @container.destroy
    redirect_to containers_url, notice: 'Container was successfully destroyed.'
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_container
      @container = Container.find(params[:id])
    end

    # Only allow a trusted parameter "white list" through.
    def container_params
      params.require(:container).permit(:description)
    end
end
