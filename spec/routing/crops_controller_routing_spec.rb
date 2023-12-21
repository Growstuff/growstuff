# frozen_string_literal: true

require "rails_helper"

describe CropsController do
  describe "routing" do
    it "routes to #index" do
      get("/crops").should route_to("crops#index")
    end

    it "routes to #new" do
      get("/crops/new").should route_to("crops#new")
    end

    it "routes to #show" do
      get("/crops/lettuce").should route_to("crops#show", slug: 'lettuce')
    end

    it { get("/crops/lettuce/plantings").should route_to("plantings#index", crop_slug: 'lettuce') }
    it { get("/crops/lettuce/harvests").should route_to("harvests#index", crop_slug: 'lettuce') }
    it { get("/crops/lettuce/seeds").should route_to("seeds#index", crop_slug: 'lettuce') }

    it "routes to #edit" do
      get("/crops/lettuce/edit").should route_to("crops#edit", slug: "lettuce")
    end

    it "routes to #create" do
      post("/crops").should route_to("crops#create")
    end

    it "routes to #update" do
      put("/crops/lettuce").should route_to("crops#update", slug: "lettuce")
    end

    it "routes to #destroy" do
      delete("/crops/lettuce").should route_to("crops#destroy", slug: "lettuce")
    end
  end
end
