# frozen_string_literal: true

require "rails_helper"

describe SeedsController do
  describe "routing" do
    it "routes to #index" do
      get("/seeds").should route_to("seeds#index")
      get("/members/fred/seeds").should route_to("seeds#index", member_slug: 'fred')
    end

    it "routes to #new" do
      get("/seeds/new").should route_to("seeds#new")
    end

    it "routes to #show" do
      get("/seeds/corn").should route_to("seeds#show", slug: 'corn')
    end

    it "routes to #edit" do
      get("/seeds/corn/edit").should route_to("seeds#edit", slug: 'corn')
    end

    it "routes to #create" do
      post("/seeds").should route_to("seeds#create")
    end

    it "routes to #update" do
      put("/seeds/corn").should route_to("seeds#update", slug: 'corn')
    end

    it "routes to #destroy" do
      delete("/seeds/corn").should route_to("seeds#destroy", slug: 'corn')
    end
  end
end
