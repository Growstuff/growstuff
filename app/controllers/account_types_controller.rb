class AccountTypesController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  # GET /account_types
  def index
    @account_types = AccountType.all
  end

  # GET /account_types/1
  def show
  end

  # GET /account_types/new
  def new
    @account_type = AccountType.new
  end

  # GET /account_types/1/edit
  def edit
  end

  # POST /account_types
  def create
    @account_type = AccountType.new(account_type_params)

    if @account_type.save
      redirect_to @account_type, notice: I18n.t('account_types.created')
    else
      render action: "new"
    end
  end

  # PUT /account_types/1
  def update
    if @account_type.update(account_type_params)
      redirect_to @account_type, notice: I18n.t('account_types.updated')
    else
      render action: "edit"
    end
  end

  # DELETE /account_types/1
  def destroy
    @account_type.destroy
    redirect_to account_types_url, notice: I18n.t('account_types.deleted')
  end

  private

  def account_type_params
    params.require(:account_type).permit(:is_paid, :is_permanent_paid, :name)
  end
end
