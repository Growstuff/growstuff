class AccountDetailsController < ApplicationController
  load_and_authorize_resource
  # GET /account_details
  # GET /account_details.json
  def index
    @account_details = AccountDetail.all

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @account_details }
    end
  end

  # GET /account_details/1
  # GET /account_details/1.json
  def show
    @account_detail = AccountDetail.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @account_detail }
    end
  end

  # GET /account_details/1/edit
  def edit
    @account_detail = AccountDetail.find(params[:id])
  end

  # PUT /account_details/1
  # PUT /account_details/1.json
  def update
    @account_detail = AccountDetail.find(params[:id])

    respond_to do |format|
      if @account_detail.update_attributes(params[:account_detail])
        format.html { redirect_to @account_detail, notice: 'Account detail was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @account_detail.errors, status: :unprocessable_entity }
      end
    end
  end

end
