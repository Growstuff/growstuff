class TradesController < ApplicationController
  before_action :authenticate_member!, except: %i(index show)
  load_and_authorize_resource
  responders :flash
  respond_to :json, :html
  def new
    @seed = Seed.find(params[:seed_id])
    @trade = Trade.new(seed_id: @seed.id, requested_by: current_member)
  end

  def create
    @trade = Trade.new(trade_params)
    @trade.requested_by = current_member
    @trade.save
    respond_with @trade
  end

  def show
    @trade = Trade.find(params[:id])
  end

  def index
    @sent_trade_requests = Trade.where(requested_by: current_member)
    @recieved_trade_requests = Trade.where(owner: current_member)
  end

  private

  def trade_params
    params.require(:trade).permit(:seed_id, :message)
  end
end
