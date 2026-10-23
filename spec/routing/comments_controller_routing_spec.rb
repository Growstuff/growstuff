# frozen_string_literal: true

require "rails_helper"

describe CommentsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/comments")).to route_to("comments#index")
    end

    it "routes to #new" do
      expect(get("/comments/new")).to route_to("comments#new")
    end

    it "routes to #show" do
      expect(get("/comments/1")).to route_to("comments#show", id: "1")
    end

    it "routes to #edit" do
      expect(get("/comments/1/edit")).to route_to("comments#edit", id: "1")
    end

    it "routes to #create" do
      expect(post("/comments")).to route_to("comments#create")
    end

    it "routes to #update" do
      expect(put("/comments/1")).to route_to("comments#update", id: "1")
    end

    it "routes to #destroy" do
      expect(delete("/comments/1")).to route_to("comments#destroy", id: "1")
    end
  end
end
