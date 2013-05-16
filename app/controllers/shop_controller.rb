class ShopController < ApplicationController
  def index
    @products = Product.all
    @order_item = OrderItem.new

    # this is (hopefully) part of a short-term hack to prevent people from
    # ordering multiple subscriptions, which would be very confusing to deal
    # with.  We check whether they have an order already in progress, and if
    # so, point that out to them and encourage them to checkout, rather than
    # letting them add more stuff to their order.

    @order = nil
    @most_recent_item = nil
    if current_member
      @order = current_member.current_order
      if @order
        @most_recent_item = @order.order_items.first
      end
    end

    respond_to do |format|
      format.html # index.html.haml
    end
  end
end
