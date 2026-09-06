# frozen_string_literal: true

require "rails_helper"

describe MembersController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/members")).to route_to("members#index")
    end

    it "routes to #new" do
      expect(get("/members/new")).to route_to("members#new")
    end

    it "routes to #show" do
      expect(get("/members/name")).to route_to("members#show", slug: "name")
    end

    it "routes to #edit" do
      expect(get("/members/name/edit")).to route_to("members#edit", slug: "name")
    end

    # it "routes to #create" do
    #   expect(post("/members")).to route_to("members#create")
    # end

    it "routes to #update" do
      expect(put("/members/name")).to route_to("members#update", slug: "name")
    end

    it "routes to #destroy" do
      expect(delete("/members/name")).to route_to("members#destroy", slug: "name")
    end

    it "routes to harvests#index" do
      expect(get("/members/name/harvests")).to route_to("harvests#index", member_slug: 'name')
    end

    it "routes to plantings#index" do
      expect(get("/members/name/plantings")).to route_to("plantings#index", member_slug: 'name')
    end
  end
end
