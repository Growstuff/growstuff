require "rails_helper"

describe CropsController do
  describe "routing" do
    it "routes to #index" do
      get("/crops").should route_to("crops#index")
    end

    it "routes to #new" do
      get("/crops/new").should route_to("crops#new")
    end

    it "routes to #show" do
      get("/crops/1").should route_to("crops#show", id: "1")
    end

    it "routes to #edit" do
      get("/crops/1/edit").should route_to("crops#edit", id: "1")
    end

    it "routes to #create" do
      post("/crops").should route_to("crops#create")
    end

    it "routes to #update" do
      put("/crops/1").should route_to("crops#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/crops/1").should route_to("crops#destroy", id: "1")
    end
  end
end
