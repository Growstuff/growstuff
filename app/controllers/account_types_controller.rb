class AccountTypesController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  # GET /account_types
  def index
    @account_types = AccountType.all
    respond_with(@account_types)
  end

  # GET /account_types/1
  def show
    respond_with(@account_types)
  end

  # GET /account_types/new
  def new
    @account_type = AccountType.new
    respond_with(@account_type)
  end

  # GET /account_types/1/edit
  def edit
    respond_with(@account_type)
  end

  # POST /account_types
  def create
    @account_type = AccountType.new(account_type_params)
    flash[:notice] = I18n.t('account_types.created') if @account_type.save
    respond_with(@account_type)
  end

  # PUT /account_types/1
  def update
    flash[:notice] = I18n.t('account_types.updated') if @account_type.update(account_type_params)
    respond_with(@account_type)
  end

  # DELETE /account_types/1
  def destroy
    @account_type.destroy
    flash[:notice] = I18n.t('account_types.deleted')
    respond_with(@account_type)
  end

  private

  def account_type_params
    params.require(:account_type).permit(:is_paid, :is_permanent_paid, :name)
  end
end
