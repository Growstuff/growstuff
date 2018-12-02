class ContainersController < ApplicationController
  # before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource

  # GET /containers
  def index
    @containers = Container.all.paginate(page: params[:page])
  end

  # GET /containers/1
  def show; end

  # GET /containers/new
  def new
    @container = Container.new
  end

  # GET /containers/1/edit
  def edit; end

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

  def set_container
    @container = Container.find(params[:id])
  end

  def container_params
    params.require(:container).permit(:description, :slug)
  end
end
