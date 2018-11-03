# frozen_string_literal: true

require "rails_helper"

describe ScientificNamesController do
  describe "routing" do
    it "routes to #index" do
      get("/scientific_names").should route_to("scientific_names#index")
    end

    it "routes to #new" do
      get("/scientific_names/new").should route_to("scientific_names#new")
    end

    it "routes to #show" do
      get("/scientific_names/1").should route_to("scientific_names#show", id: "1")
    end

    it "routes to #edit" do
      get("/scientific_names/1/edit").should route_to("scientific_names#edit", id: "1")
    end

    it "routes to #create" do
      post("/scientific_names").should route_to("scientific_names#create")
    end

    it "routes to #update" do
      put("/scientific_names/1").should route_to("scientific_names#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/scientific_names/1").should route_to("scientific_names#destroy", id: "1")
    end
  end
end
