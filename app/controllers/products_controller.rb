class ProductsController < ApplicationController
  before_action :authenticate_member!
  load_and_authorize_resource
  respond_to :html

  def index
    @products = Product.all
    respond_with @products
  end

  def show
    respond_with @product
  end

  def new
    @product = Product.new
    respond_with @product
  end

  def edit
    respond_with @product
  end

  def create
    @product = Product.create(product_params)
    respond_with @product
  end

  def update
    @product.update(product_params)
    respond_with @product
  end

  def destroy
    @product.destroy
    respond_with @product
  end

  private

  def product_params
    params.require(:product).permit(:description, :min_price, :recommended_price, :name,
      :account_type_id, :paid_months)
  end
end
