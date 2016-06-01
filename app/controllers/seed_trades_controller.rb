class SeedTradesController < ApplicationController
  before_filter :authenticate_member!
  before_action :set_seed_trade, except:[:index, :new, :create]

  load_and_authorize_resource

  respond_to :html

  # GET /seed_trades
  def index
    @seed_trades = SeedTrade.by_member(current_member).page(params[:page])
  end

  # GET /seed_trades/1
  def show
  end

  # GET /seed_trades/new?seed_id=1
  def new
    @seed       = Seed.find(params[:seed_id])
    @seed_trade = @seed.seed_trades.build
  end

  # POST /seed_trades
  def create
    @seed_trade = current_member.seed_trades.build(seed_trade_params)

    if @seed_trade.save
      send_new_seed_request_email(@seed_trade)
      redirect_to member_seed_trades_path,
        notice: 'A seed trade request was successfully created.'
    else
      @seed = @seed_trade.seed
      render :new
    end
  end

  # PATCH /seed_trades/1/decline
  def decline
    @seed_trade.update_columns(declined_date: Time.zone.now)
    redirect_to member_seed_trades_path,
      notice: 'You have successfully declined this request.'
  end

  # PATCH /seed_trades/1/accept
  def accept
    @seed_trade.update_columns(accepted_date: Time.zone.now)
    redirect_to member_seed_trades_path,
      notice: 'You have successfully accepted this request.'
  end

  # PATCH /seed_trades/1/send_seed
  def send_seed
    @seed_trade.update_columns(sent_date: Time.zone.now)
    redirect_to member_seed_trades_path,
      notice: 'You have successfully marked this request as sent.'
  end

  # PATCH /seed_trades/1/receive
  def receive
    @seed_trade.update_columns(received_date: Time.zone.now)
    redirect_to member_seed_trades_path,
      notice: 'You have successfully marked this request as received.'
  end

  private

  def set_seed_trade
    @seed_trade = SeedTrade.find(params[:id])
  end

  def send_new_seed_request_email(seed_trade)
    if seed_trade.seed.owner.send_notification_email
      Notifier.new_seed_trade_request(seed_trade).deliver!
    end
  end

  def seed_trade_params
    params.require(:seed_trade).permit(:requester_id, :seed_id, :message, :address)
  end
end
