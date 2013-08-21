class AccountsController < ApplicationController
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
      if @account.update_attributes(params[:account])
        format.html { redirect_to @account, notice: 'Account detail was successfully updated.' }
      else
        format.html { render action: "edit" }
      end
    end
  end

end
