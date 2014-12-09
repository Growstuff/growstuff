class AccountTypesController < ApplicationController
  before_filter :authenticate_member!
  load_and_authorize_resource
  
  # GET /account_types
  def index
    @account_types = AccountType.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /account_types/1
  def show
    @account_type = AccountType.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /account_types/new
  def new
    @account_type = AccountType.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # GET /account_types/1/edit
  def edit
    @account_type = AccountType.find(params[:id])
  end

  # POST /account_types
  def create
    @account_type = AccountType.new(params[:account_type])

    respond_to do |format|
      if @account_type.save
        format.html { redirect_to @account_type, notice: 'Account type was successfully created.' }
      else
        format.html { render action: "new" }
      end
    end
  end

  # PUT /account_types/1
  def update
    @account_type = AccountType.find(params[:id])

    respond_to do |format|
      if @account_type.update_attributes(params[:account_type])
        format.html { redirect_to @account_type, notice: 'Account type was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /account_types/1
  def destroy
    @account_type = AccountType.find(params[:id])
    @account_type.destroy

    respond_to do |format|
      format.html { redirect_to account_types_url, notice: 'Account type was successfully deleted.' }
    end
  end
end
