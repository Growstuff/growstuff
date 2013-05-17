require "spec_helper"

describe AccountDetailsController do
  describe "routing" do

    it "routes to #index" do
      get("/account_details").should route_to("account_details#index")
    end

    it "routes to #new" do
      get("/account_details/new").should route_to("account_details#new")
    end

    it "routes to #show" do
      get("/account_details/1").should route_to("account_details#show", :id => "1")
    end

    it "routes to #edit" do
      get("/account_details/1/edit").should route_to("account_details#edit", :id => "1")
    end

    it "routes to #create" do
      post("/account_details").should route_to("account_details#create")
    end

    it "routes to #update" do
      put("/account_details/1").should route_to("account_details#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/account_details/1").should route_to("account_details#destroy", :id => "1")
    end

  end
end
