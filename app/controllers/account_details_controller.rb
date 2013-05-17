class AccountDetailsController < ApplicationController
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

  # GET /account_details/new
  # GET /account_details/new.json
  def new
    @account_detail = AccountDetail.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @account_detail }
    end
  end

  # GET /account_details/1/edit
  def edit
    @account_detail = AccountDetail.find(params[:id])
  end

  # POST /account_details
  # POST /account_details.json
  def create
    @account_detail = AccountDetail.new(params[:account_detail])

    respond_to do |format|
      if @account_detail.save
        format.html { redirect_to @account_detail, notice: 'Account detail was successfully created.' }
        format.json { render json: @account_detail, status: :created, location: @account_detail }
      else
        format.html { render action: "new" }
        format.json { render json: @account_detail.errors, status: :unprocessable_entity }
      end
    end
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

  # DELETE /account_details/1
  # DELETE /account_details/1.json
  def destroy
    @account_detail = AccountDetail.find(params[:id])
    @account_detail.destroy

    respond_to do |format|
      format.html { redirect_to account_details_url }
      format.json { head :no_content }
    end
  end
end
