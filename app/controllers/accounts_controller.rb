class AccountsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  # GET /accounts
  def index
    @accounts = Account.all
    respond_with(@accounts)
  end

  # GET /accounts/1
  def show
    respond_with(@account)
  end

  # GET /accounts/1/edit
  def edit
  end

  # PUT /accounts/1
  def update
    flash[:notice] = I18n.t('account.update') if @account.update(params[:account])
    respond_with(@account)
  end

  private

  def account_params
    params.require(:account).permit(:account_type_id, :member_id, :paid_until)
  end
end
