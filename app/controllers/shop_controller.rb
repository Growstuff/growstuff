class ShopController < ApplicationController
  def index
    @products = Product.all
    respond_to do |format|
      format.html # index.html.haml
    end
  end
end
