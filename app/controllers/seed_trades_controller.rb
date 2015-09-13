class SeedTradesController < ApplicationController
  before_filter :authenticate_member!
  load_and_authorize_resource

  # GET /seed_trades
  def index
    @seed_trades = SeedTrade.by_member(current_member).page(params[:page])
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET member/1/seed_trades/1
  def show
    @seed_trade = SeedTrade.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /notifications/new
  def new
    @seed_trade = SeedTrade.new
    @recipient  = Member.find_by_id(params[:recipient_id])
    @seed       = Seed.find(params[:seed_id])

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @seed_trade = current_member.seed_trades.build(seed_trade_params)

    respond_to do |format|
      if @seed_trade.seed && @seed_trade.save
        format.html { redirect_to member_seed_trades_path,
          notice: 'A seed trade request was successfully sent.' }
      else
        format.html { render :new }
      end
    end
  end

  def seed_trade_params
    params.require(:seed_trade).permit(:requester_id, :seed_id, :message, :address)
  end
end
