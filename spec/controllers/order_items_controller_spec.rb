require 'spec_helper'

describe OrderItemsController do

  login_member(:admin_member)

  def valid_attributes
    { "order_id" => "1", "product_id" => "1" }
  end

  describe "GET index" do
    it "assigns all order_items as @order_items" do
      order_item = OrderItem.create! valid_attributes
      get :index, {}
      assigns(:order_items).should eq([order_item])
    end
  end

  describe "GET show" do
    it "assigns the requested order_item as @order_item" do
      order_item = OrderItem.create! valid_attributes
      get :show, {:id => order_item.to_param}
      assigns(:order_item).should eq(order_item)
    end
  end

  describe "GET new" do
    it "assigns a new order_item as @order_item" do
      get :new, {}
      assigns(:order_item).should be_a_new(OrderItem)
    end
  end

  describe "GET edit" do
    it "assigns the requested order_item as @order_item" do
      order_item = OrderItem.create! valid_attributes
      get :edit, {:id => order_item.to_param}
      assigns(:order_item).should eq(order_item)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new OrderItem" do
        expect {
          post :create, {:order_item => valid_attributes}
        }.to change(OrderItem, :count).by(1)
      end

      it "assigns a newly created order_item as @order_item" do
        post :create, {:order_item => valid_attributes}
        assigns(:order_item).should be_a(OrderItem)
        assigns(:order_item).should be_persisted
      end

      it "redirects to the created order_item" do
        post :create, {:order_item => valid_attributes}
        response.should redirect_to(OrderItem.last)
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved order_item as @order_item" do
        # Trigger the behavior that occurs when invalid params are submitted
        OrderItem.any_instance.stub(:save).and_return(false)
        post :create, {:order_item => { "order_id" => "invalid value" }}
        assigns(:order_item).should be_a_new(OrderItem)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        OrderItem.any_instance.stub(:save).and_return(false)
        post :create, {:order_item => { "order_id" => "invalid value" }}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested order_item" do
        order_item = OrderItem.create! valid_attributes
        # Assuming there are no other order_items in the database, this
        # specifies that the OrderItem created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        OrderItem.any_instance.should_receive(:update_attributes).with({ "order_id" => "1" })
        put :update, {:id => order_item.to_param, :order_item => { "order_id" => "1" }}
      end

      it "assigns the requested order_item as @order_item" do
        order_item = OrderItem.create! valid_attributes
        put :update, {:id => order_item.to_param, :order_item => valid_attributes}
        assigns(:order_item).should eq(order_item)
      end

      it "redirects to the order_item" do
        order_item = OrderItem.create! valid_attributes
        put :update, {:id => order_item.to_param, :order_item => valid_attributes}
        response.should redirect_to(order_item)
      end
    end

    describe "with invalid params" do
      it "assigns the order_item as @order_item" do
        order_item = OrderItem.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        OrderItem.any_instance.stub(:save).and_return(false)
        put :update, {:id => order_item.to_param, :order_item => { "order_id" => "invalid value" }}
        assigns(:order_item).should eq(order_item)
      end

      it "re-renders the 'edit' template" do
        order_item = OrderItem.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        OrderItem.any_instance.stub(:save).and_return(false)
        put :update, {:id => order_item.to_param, :order_item => { "order_id" => "invalid value" }}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested order_item" do
      order_item = OrderItem.create! valid_attributes
      expect {
        delete :destroy, {:id => order_item.to_param}
      }.to change(OrderItem, :count).by(-1)
    end

    it "redirects to the order_items list" do
      order_item = OrderItem.create! valid_attributes
      delete :destroy, {:id => order_item.to_param}
      response.should redirect_to(order_items_url)
    end
  end

end
