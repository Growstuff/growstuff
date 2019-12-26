# frozen_string_literal: true

require "rails_helper"

describe PlantPartsController do
  describe "routing" do
    it "routes to #index" do
      get("/plant_parts").should route_to("plant_parts#index")
    end

    it "routes to #new" do
      get("/plant_parts/new").should route_to("plant_parts#new")
    end

    it "routes to #show" do
      get("/plant_parts/1").should route_to("plant_parts#show", id: "1")
    end

    it "routes to #edit" do
      get("/plant_parts/1/edit").should route_to("plant_parts#edit", id: "1")
    end

    it "routes to #create" do
      post("/plant_parts").should route_to("plant_parts#create")
    end

    it "routes to #update" do
      put("/plant_parts/1").should route_to("plant_parts#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/plant_parts/1").should route_to("plant_parts#destroy", id: "1")
    end
  end
end
