class AccountsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  # GET /accounts
  def index
    @accounts = Account.all
  end

  # GET /accounts/1
  def show
  end

  # GET /accounts/1/edit
  def edit
  end

  # PUT /accounts/1
  def update
    if @account.update(params[:account])
      redirect_to @account, notice: I18n.t('account.update')
    else
      render action: "edit"
    end
  end

  private

  def account_params
    params.require(:account).permit(:account_type_id, :member_id, :paid_until)
  end
end
