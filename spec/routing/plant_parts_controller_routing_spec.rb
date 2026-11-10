# frozen_string_literal: true

require "rails_helper"

describe PlantPartsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/plant_parts")).to route_to("plant_parts#index")
    end

    it "routes to #new" do
      expect(get("/plant_parts/new")).to route_to("plant_parts#new")
    end

    it "routes to #show" do
      expect(get("/plant_parts/1")).to route_to("plant_parts#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/plant_parts/1/edit")).to route_to("plant_parts#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/plant_parts")).to route_to("plant_parts#create")
    end

    it "routes to #update" do
      expect(put("/plant_parts/1")).to route_to("plant_parts#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/plant_parts/1")).to route_to("plant_parts#destroy", id: "1")
    end
  end
end
