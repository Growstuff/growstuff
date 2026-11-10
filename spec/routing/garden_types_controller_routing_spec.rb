# frozen_string_literal: true

require "rails_helper"

describe GardenTypesController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/garden_types")).to route_to("garden_types#index")
    end

    it "routes to #new" do
      expect(get("/garden_types/new")).to route_to("garden_types#new")
    end

    it "routes to #show" do
      expect(get("/garden_types/1")).to route_to("garden_types#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/garden_types/1/edit")).to route_to("garden_types#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/garden_types")).to route_to("garden_types#create")
    end

    it "routes to #update" do
      expect(put("/garden_types/1")).to route_to("garden_types#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/garden_types/1")).to route_to("garden_types#destroy", id: "1")
    end
  end
end
