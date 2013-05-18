class OrdersController < ApplicationController
  load_and_authorize_resource

  # GET /orders
  def index
    @orders = Order.find_all_by_member_id(current_member.id)

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

  def complete
    @order = Order.find(params[:id])

    @order.completed_at = Time.zone.now
    @order.save

    @order.update_account # apply paid account benefits, etc.

    respond_to do |format|
      format.html # new.html.erb
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
