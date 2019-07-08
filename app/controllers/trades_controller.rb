class TradesController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  respond_to :json, :html
  def new
    @seed = Seed.find(params[:seed_id])
  end

  def create
    @trade = Trade.create(trade_params)
    respond_with @trade
  end

  def show
    @trade = Trade.find(params[:id])
  end

  private

  def trade_params
    params.require(:trade).permit(:seed_id, :info)
  end
end
