class Admin::OrdersController < ApplicationController
  def index
    authorize! :manage, :all
    respond_to do |format|
      format.html # index.html.haml
    end
  end

  def search
    authorize! :manage, :all
    @orders = []

    if params[:search_text]
      case params[:search_by]
        when "member"
          member = Member.find_by_login_name(params[:search_text])
          if member
            @orders = member.orders
          end
        when "order_id"
          order = Order.find_by_id(params[:search_text])
          if order
            @orders = [order]
          end
        when "paypal_token"
          order = Order.find_by_paypal_express_token(params[:search_text])
          if order
            @orders = [order]
          end
        when "paypal_payer_id"
          order = Order.find_by_paypal_express_payer_id(params[:search_text])
          if order
            @orders = [order]
          end
      end
      if @orders.empty?
        flash[:alert] = "Couldn't find order with #{params[:search_by]} = #{params[:search_text]}"
      end
    end

    respond_to do |format|
      format.html # index.html.haml
    end

  end
end
