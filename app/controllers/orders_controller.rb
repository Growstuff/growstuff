class OrdersController < ApplicationController
  before_filter :authenticate_member!
  load_and_authorize_resource

  # GET /orders
  def index
    @orders = Order.where(member_id: current_member.id)

    respond_to do |format|
      format.html # index.html.erb
    end
  end

  # GET /orders/1
  def show
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
    end
  end

  # GET /orders/new
  def new
    @order = Order.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  # checkout with PayPal
  def checkout
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(referral_code: params[:referral_code])
        response = EXPRESS_GATEWAY.setup_purchase(
          @order.total,
          items: @order.activemerchant_items,
          currency: Growstuff::Application.config.currency,
          no_shipping: true,
          ip: request.remote_ip,
          return_url: complete_order_url,
          cancel_return_url: shop_url
        )
        format.html { redirect_to EXPRESS_GATEWAY.redirect_url_for(response.token) }
      else
        format.html { render action: "show" }
      end
    end

  end

  def complete
    @order = Order.find(params[:id])

    if (params[:token] && params['PayerID'])
      purchase = EXPRESS_GATEWAY.purchase(
        @order.total,
        currency: Growstuff::Application.config.currency,
        ip: request.remote_ip,
        payer_id: params['PayerID'],
        token: params[:token]
      )
      if purchase.success?
        @order.completed_at = Time.zone.now
        @order.record_paypal_details(params[:token])
      else
        flash[:alert] = "Could not complete your order. Please notify support."
      end
    else
      flash[:alert] = "PayPal didn't return a token or payer_id for your order.  Please notify support."
    end

    @order.update_account # apply paid account benefits, etc.

    respond_to do |format|
      format.html # new.html.erb
    end

  end

  def cancel
    @order = Order.find(params[:id])
    respond_to do |format|
      format.html { redirect_to shop_url, notice: 'Order was cancelled.' }
    end
  end

  # DELETE /orders/1
  def destroy
    @order = Order.find(params[:id])
    @order.destroy

    respond_to do |format|
      format.html { redirect_to shop_url, notice: 'Order was deleted.' }
    end
  end
end
