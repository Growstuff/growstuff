require "spec_helper"

describe OrderItemsController do
  describe "routing" do

    it "routes to #index" do
      get("/order_items").should route_to("order_items#index")
    end

    it "routes to #new" do
      get("/order_items/new").should route_to("order_items#new")
    end

    it "routes to #show" do
      get("/order_items/1").should route_to("order_items#show", :id => "1")
    end

    it "routes to #edit" do
      get("/order_items/1/edit").should route_to("order_items#edit", :id => "1")
    end

    it "routes to #create" do
      post("/order_items").should route_to("order_items#create")
    end

    it "routes to #update" do
      put("/order_items/1").should route_to("order_items#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/order_items/1").should route_to("order_items#destroy", :id => "1")
    end

  end
end
