class RolesController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource

  # GET /roles
  def index
    @roles = Role.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /roles/1
  def show
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /roles/new
  def new
    @role = Role.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /roles/1/edit
  def edit
  end

  # POST /roles
  def create
    @role = Role.new(role_params)

    respond_to do |format|
      if @role.save
        format.html { redirect_to @role, notice: 'Role was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /roles/1
  def update
    respond_to do |format|
      if @role.update(role_params)
        format.html { redirect_to @role, notice: 'Role was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /roles/1
  def destroy
    @role.destroy

    respond_to do |format|
      format.html { redirect_to roles_url }
    end
  end

  private

  def role_params
    params.require(:role).permit(:description, :name, :members, :slug)
  end
end
