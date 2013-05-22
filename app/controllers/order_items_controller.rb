class OrderItemsController < ApplicationController
  load_and_authorize_resource

  # POST /order_items
  # POST /order_items.json
  def create
    @order_item = OrderItem.new(params[:order_item])
    @order_item.price = @order_item.price.to_f * 100 # convert to cents
    @order_item.order = current_member.current_order || Order.create(:member_id => current_member.id)

    respond_to do |format|
      if @order_item.save
        format.html { redirect_to @order_item.order, notice: 'Added item to your order.' }
        format.json { render json: @order_item, status: :created, location: @order_item }
      else
        format.html { redirect_to shop_path, alert: 'There was a problem with your order' }
        format.json { render json: @order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /order_items/1
  # PUT /order_items/1.json
  def update
    @order_item = OrderItem.find(params[:id])
    @order_item.price = @order_item.price.to_f * 100 # convert to cents

    respond_to do |format|
      if @order_item.update_attributes(params[:order_item])
        format.html { redirect_to @order_item.order, notice: 'Order item was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @order_item.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /order_items/1
  # DELETE /order_items/1.json
  def destroy
    @order_item = OrderItem.find(params[:id])
    @order_item.destroy

    respond_to do |format|
      format.html { redirect_to order_items_url }
      format.json { head :no_content }
    end
  end
end
