class AccountTypesController < ApplicationController
  before_action :authenticate_member!
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
  end

  # POST /account_types
  def create
    @account_type = AccountType.new(account_type_params)

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
    respond_to do |format|
      if @account_type.update(account_type_params)
        format.html { redirect_to @account_type, notice: 'Account type was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  # DELETE /account_types/1
  def destroy
    @account_type.destroy

    respond_to do |format|
      format.html { redirect_to account_types_url, notice: 'Account type was successfully deleted.' }
    end
  end

  private

  def account_type_params
    params.require(:account_type).permit(:is_paid, :is_permanent_paid, :name)
  end
end
