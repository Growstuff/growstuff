# frozen_string_literal: true

require "rails_helper"

describe HarvestsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/harvests")).to route_to("harvests#index")
      expect(get("/members/fred/harvests")).to route_to("harvests#index", member_slug: 'fred')
    end

    it "routes to #new" do
      expect(get("/harvests/new")).to route_to("harvests#new")
    end

    it "routes to #show" do
      expect(get("/harvests/potato")).to route_to("harvests#show", slug: "potato")
    end

    it "routes to #edit" do
      expect(get("/harvests/potato/edit")).to route_to("harvests#edit", slug: "potato")
    end

    it "routes to #create" do
      expect(post("/harvests")).to route_to("harvests#create")
    end

    it "routes to #update" do
      expect(put("/harvests/potato")).to route_to("harvests#update", slug: "potato")
    end

    it "routes to #destroy" do
      expect(delete("/harvests/potato")).to route_to("harvests#destroy", slug: "potato")
    end
  end
end
