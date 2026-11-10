# frozen_string_literal: true

require "rails_helper"

describe ForumsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/forums")).to route_to("forums#index")
    end

    it "routes to #new" do
      expect(get("/forums/new")).to route_to("forums#new")
    end

    it "routes to #show" do
      expect(get("/forums/1")).to route_to("forums#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/forums/1/edit")).to route_to("forums#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/forums")).to route_to("forums#create")
    end

    it "routes to #update" do
      expect(put("/forums/1")).to route_to("forums#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/forums/1")).to route_to("forums#destroy", id: "1")
    end
  end
end
