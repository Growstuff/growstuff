# frozen_string_literal: true

require "rails_helper"

describe PlantingsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/plantings")).to route_to("plantings#index")
      expect(get("/members/fred/plantings")).to route_to("plantings#index", member_slug: 'fred')
    end

    it "routes to #new" do
      expect(get("/plantings/new")).to route_to("plantings#new")
    end

    it "routes to #show" do
      expect(get("/plantings/tomato")).to route_to("plantings#show", slug: "tomato")
    end

    it "routes to #edit" do
      expect(get("/plantings/tomato/edit")).to route_to("plantings#edit", slug: "tomato")
    end

    it "routes to #create" do
      expect(post("/plantings")).to route_to("plantings#create")
    end

    it "routes to #update" do
      expect(put("/plantings/tomato")).to route_to("plantings#update", slug: "tomato")
    end

    it "routes to #destroy" do
      expect(delete("/plantings/tomato")).to route_to("plantings#destroy", slug: "tomato")
    end
  end
end
