class Admin::OrdersController < ApplicationController
  def index
    authorize! :manage, :all
    respond_to do |format|
      format.html # index.html.haml
    end
  end

  def search
    @orders = nil

    if params[:search_text]
      case params[:search_by]
        when "member"
          begin
            @member = Member.find(params[:search_text])
            @orders = @member.orders
          rescue ActiveRecord::RecordNotFound
            flash[:alert] = "Couldn't find member with name #{params[:search_text]}"
          end
        when "order_id"
          begin
            @orders = [ Order.find(params[:search_text]) ]
          rescue ActiveRecord::RecordNotFound
            flash[:alert] = "Couldn't find order with id #{params[:search_text]}"
          end
        when "paypal_token"
          @orders = [ Order.find_by_paypal_express_token(params[:search_text]) ]
          if @orders.nil?
            flash[:alert] = "Couldn't find order with paypal token #{params[:search_text]}"
          end
        when "paypal_payer_id"
          @orders = [ Order.find_by_paypal_express_payer_id(params[:search_text]) ]
          if @orders.nil?
            flash[:alert] = "Couldn't find order with paypal payer id #{params[:search_text]}"
          end
      end
    end

    respond_to do |format|
      format.html # index.html.haml
    end

  end
end
