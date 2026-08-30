# frozen_string_literal: true

require "rails_helper"

describe SeedsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/seeds")).to route_to("seeds#index")
      expect(get("/members/fred/seeds")).to route_to("seeds#index", member_slug: 'fred')
    end

    it "routes to #new" do
      expect(get("/seeds/new")).to route_to("seeds#new")
    end

    it "routes to #show" do
      expect(get("/seeds/corn")).to route_to("seeds#show", slug: 'corn')
    end

    it "routes to #edit" do
      expect(get("/seeds/corn/edit")).to route_to("seeds#edit", slug: 'corn')
    end

    it "routes to #create" do
      expect(post("/seeds")).to route_to("seeds#create")
    end

    it "routes to #update" do
      expect(put("/seeds/corn")).to route_to("seeds#update", slug: 'corn')
    end

    it "routes to #destroy" do
      expect(delete("/seeds/corn")).to route_to("seeds#destroy", slug: 'corn')
    end
  end
end
