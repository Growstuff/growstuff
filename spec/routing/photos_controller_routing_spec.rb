# frozen_string_literal: true

require "rails_helper"

describe PhotosController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/photos")).to route_to("photos#index")
    end

    it "routes to #new" do
      expect(get("/photos/new")).to route_to("photos#new")
    end

    it "routes to #show" do
      expect(get("/photos/1")).to route_to("photos#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/photos/1/edit")).to route_to("photos#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/photos")).to route_to("photos#create")
    end

    it "routes to #update" do
      expect(put("/photos/1")).to route_to("photos#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/photos/1")).to route_to("photos#destroy", id: "1")
    end
  end
end
