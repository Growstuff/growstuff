# frozen_string_literal: true

require "rails_helper"

describe ForumsController do
  describe "routing" do
    it "routes to #index" do
      get("/forums").should route_to("forums#index")
    end

    it "routes to #new" do
      get("/forums/new").should route_to("forums#new")
    end

    it "routes to #show" do
      get("/forums/1").should route_to("forums#show", id: "1")
    end

    it "routes to #edit" do
      get("/forums/1/edit").should route_to("forums#edit", id: "1")
    end

    it "routes to #create" do
      post("/forums").should route_to("forums#create")
    end

    it "routes to #update" do
      put("/forums/1").should route_to("forums#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/forums/1").should route_to("forums#destroy", id: "1")
    end
  end
end
