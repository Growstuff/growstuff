require "rails_helper"

describe HarvestsController do
  describe "routing" do
    it "routes to #index" do
      get("/harvests").should route_to("harvests#index")
    end

    it "routes to #new" do
      get("/harvests/new").should route_to("harvests#new")
    end

    it "routes to #show" do
      get("/harvests/1").should route_to("harvests#show", id: "1")
    end

    it "routes to #edit" do
      get("/harvests/1/edit").should route_to("harvests#edit", id: "1")
    end

    it "routes to #create" do
      post("/harvests").should route_to("harvests#create")
    end

    it "routes to #update" do
      put("/harvests/1").should route_to("harvests#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/harvests/1").should route_to("harvests#destroy", id: "1")
    end
  end
end
