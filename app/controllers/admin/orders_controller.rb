class Admin::OrdersController < ApplicationController
  def index
    authorize! :manage, :all
    respond_to do |format|
      format.html # index.html.haml
    end
  end

  def search
    authorize! :manage, :all
    @orders = Order.search({by: params[:search_by], for: params[:search_text]})

    if @orders.empty?
      flash[:alert] = "Couldn't find order with #{params[:search_by]} = #{params[:search_text]}"
    end

    respond_to do |format|
      format.html # index.html.haml
    end

  end
end
