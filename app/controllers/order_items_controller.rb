class OrderItemsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html
  responders :flash

  # POST /order_items
  def create
    if params[:order_item][:price]
      params[:order_item][:price] = params[:order_item][:price].to_f * 100 # convert to cents
    end

    @order_item = OrderItem.new(order_item_params)
    @order_item.order = current_member.current_order || Order.create(member_id: current_member.id)

    if @order_item.save
      redirect_to @order_item.order, notice: 'Added item to your order.'
    else
      redirect_to shop_path, alert: errors
    end
  end

  private

  def errors
    if @order_item.errors.empty?
      "There was a problem with your order."
    else
      @order_item.errors.full_messages.to_sentence
    end
  end

  def order_item_params
    params.require(:order_item).permit(:order_id, :price, :product_id, :quantity)
  end
end
