# frozen_string_literal: true

require "rails_helper"

describe ScientificNamesController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/scientific_names")).to route_to("scientific_names#index")
    end

    it "routes to #new" do
      expect(get("/scientific_names/new")).to route_to("scientific_names#new")
    end

    it "routes to #show" do
      expect(get("/scientific_names/1")).to route_to("scientific_names#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/scientific_names/1/edit")).to route_to("scientific_names#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/scientific_names")).to route_to("scientific_names#create")
    end

    it "routes to #update" do
      expect(put("/scientific_names/1")).to route_to("scientific_names#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/scientific_names/1")).to route_to("scientific_names#destroy", id: "1")
    end
  end
end
