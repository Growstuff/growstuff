class OrderItemsController < ApplicationController
  load_and_authorize_resource

  # POST /order_items
  def create
    if params[:order_item][:price]
      params[:order_item][:price] = params[:order_item][:price].to_f * 100 # convert to cents
    end
    @order_item = OrderItem.new(params[:order_item])
    @order_item.order = current_member.current_order || Order.create(:member_id => current_member.id)

    respond_to do |format|
      if @order_item.save
        format.html { redirect_to @order_item.order, notice: 'Added item to your order.' }
      else
        errors = @order_item.errors.empty? ?
          "There was a problem with your order." : @order_item.errors.full_messages.to_sentence
        format.html { redirect_to shop_path, alert: errors }
      end
    end
  end
end
