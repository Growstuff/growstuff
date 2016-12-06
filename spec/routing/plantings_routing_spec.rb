require "rails_helper"

describe PlantingsController do
  describe "routing" do
    it "routes to #index" do
      get("/plantings").should route_to("plantings#index")
    end

    it "routes to #new" do
      get("/plantings/new").should route_to("plantings#new")
    end

    it "routes to #show" do
      get("/plantings/1").should route_to("plantings#show", id: "1")
    end

    it "routes to #edit" do
      get("/plantings/1/edit").should route_to("plantings#edit", id: "1")
    end

    it "routes to #create" do
      post("/plantings").should route_to("plantings#create")
    end

    it "routes to #update" do
      put("/plantings/1").should route_to("plantings#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/plantings/1").should route_to("plantings#destroy", id: "1")
    end
  end
end
