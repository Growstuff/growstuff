class ShopController < ApplicationController
  def index
    @products = Product.all
    @order_item = OrderItem.new
    respond_to do |format|
      format.html # index.html.haml
    end
  end
end
