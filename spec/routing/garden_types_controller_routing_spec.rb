# frozen_string_literal: true

require "rails_helper"

describe GardenTypesController do
  describe "routing" do
    it "routes to #index" do
      get("/garden_types").should route_to("garden_types#index")
    end

    it "routes to #new" do
      get("/garden_types/new").should route_to("garden_types#new")
    end

    it "routes to #show" do
      get("/garden_types/1").should route_to("garden_types#show", id: "1")
    end

    it "routes to #edit" do
      get("/garden_types/1/edit").should route_to("garden_types#edit", id: "1")
    end

    it "routes to #create" do
      post("/garden_types").should route_to("garden_types#create")
    end

    it "routes to #update" do
      put("/garden_types/1").should route_to("garden_types#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/garden_types/1").should route_to("garden_types#destroy", id: "1")
    end
  end
end
