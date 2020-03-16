# frozen_string_literal: true

require "rails_helper"

describe HarvestsController do
  describe "routing" do
    it "routes to #index" do
      get("/harvests").should route_to("harvests#index")
      get("/members/fred/harvests").should route_to("harvests#index", member_slug: 'fred')
    end

    it "routes to #new" do
      get("/harvests/new").should route_to("harvests#new")
    end

    it "routes to #show" do
      get("/harvests/potato").should route_to("harvests#show", slug: "potato")
    end

    it "routes to #edit" do
      get("/harvests/potato/edit").should route_to("harvests#edit", slug: "potato")
    end

    it "routes to #create" do
      post("/harvests").should route_to("harvests#create")
    end

    it "routes to #update" do
      put("/harvests/potato").should route_to("harvests#update", slug: "potato")
    end

    it "routes to #destroy" do
      delete("/harvests/potato").should route_to("harvests#destroy", slug: "potato")
    end
  end
end
