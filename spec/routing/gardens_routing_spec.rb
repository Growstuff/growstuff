# frozen_string_literal: true

require "rails_helper"

describe GardensController do
  describe "routing" do
    it "routes to #index" do
      get("/gardens").should route_to("gardens#index")
      get("/members/fred/gardens").should route_to("gardens#index", member_slug: 'fred')
    end

    it "routes to #new" do
      get("/gardens/new").should route_to("gardens#new")
    end

    it "routes to #show" do
      get("/gardens/sunny-bed").should route_to("gardens#show", slug: 'sunny-bed')
    end

    it "routes to #edit" do
      get("/gardens/sunny-bed/edit").should route_to("gardens#edit", slug: 'sunny-bed')
    end

    it "routes to #create" do
      post("/gardens").should route_to("gardens#create")
    end

    it "routes to #update" do
      put("/gardens/sunny-bed").should route_to("gardens#update", slug: 'sunny-bed')
    end

    it "routes to #destroy" do
      delete("/gardens/sunny-bed").should route_to("gardens#destroy", slug: 'sunny-bed')
    end
  end
end
