require "spec_helper"

describe AccountTypesController do
  describe "routing" do

    it "routes to #index" do
      get("/account_types").should route_to("account_types#index")
    end

    it "routes to #new" do
      get("/account_types/new").should route_to("account_types#new")
    end

    it "routes to #show" do
      get("/account_types/1").should route_to("account_types#show", :id => "1")
    end

    it "routes to #edit" do
      get("/account_types/1/edit").should route_to("account_types#edit", :id => "1")
    end

    it "routes to #create" do
      post("/account_types").should route_to("account_types#create")
    end

    it "routes to #update" do
      put("/account_types/1").should route_to("account_types#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/account_types/1").should route_to("account_types#destroy", :id => "1")
    end

  end
end
