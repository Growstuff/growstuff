class AccountsController < ApplicationController
  before_filter :authenticate_member!
  load_and_authorize_resource

  # GET /accounts
  def index
    @accounts = Account.all

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /accounts/1
  def show
    @account = Account.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /accounts/1/edit
  def edit
    @account = Account.find(params[:id])
  end

  # PUT /accounts/1
  def update
    @account = Account.find(params[:id])

    respond_to do |format|
      if @account.update(params[:account])
        format.html { redirect_to @account, notice: 'Account detail was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

  private

  def account_params
    params.require(:account).permit(:account_type_id, :member_id, :paid_until)
  end
end
