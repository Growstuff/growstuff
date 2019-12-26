# frozen_string_literal: true

require "rails_helper"

describe MembersController do
  describe "routing" do
    it "routes to #index" do
      get("/members").should route_to("members#index")
    end

    it "routes to #new" do
      get("/members/new").should route_to("members#new")
    end

    it "routes to #show" do
      get("/members/name").should route_to("members#show", slug: "name")
    end

    it "routes to #edit" do
      get("/members/name/edit").should route_to("members#edit", slug: "name")
    end

    # it "routes to #create" do
    #   post("/members").should route_to("members#create")
    # end

    it "routes to #update" do
      put("/members/name").should route_to("members#update", slug: "name")
    end

    it "routes to #destroy" do
      delete("/members/name").should route_to("members#destroy", slug: "name")
    end

    it "routes to harvests#index" do
      get("/members/name/harvests").should route_to("harvests#index", member_slug: 'name')
    end
    it "routes to plantings#index" do
      get("/members/name/plantings").should route_to("plantings#index", member_slug: 'name')
    end
  end
end
