# frozen_string_literal: true

require "rails_helper"

describe PlantingsController do
  describe "routing" do
    it "routes to #index" do
      get("/plantings").should route_to("plantings#index")
      get("/members/fred/plantings").should route_to("plantings#index", member_slug: 'fred')
    end

    it "routes to #new" do
      get("/plantings/new").should route_to("plantings#new")
    end

    it "routes to #show" do
      get("/plantings/tomato").should route_to("plantings#show", slug: "tomato")
    end

    it "routes to #edit" do
      get("/plantings/tomato/edit").should route_to("plantings#edit", slug: "tomato")
    end

    it "routes to #create" do
      post("/plantings").should route_to("plantings#create")
    end

    it "routes to #update" do
      put("/plantings/tomato").should route_to("plantings#update", slug: "tomato")
    end

    it "routes to #destroy" do
      delete("/plantings/tomato").should route_to("plantings#destroy", slug: "tomato")
    end
  end
end
