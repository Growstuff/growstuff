# frozen_string_literal: true

require "rails_helper"

describe GardensController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/gardens")).to route_to("gardens#index")
      expect(get("/members/fred/gardens")).to route_to("gardens#index", member_slug: 'fred')
    end

    it "routes to #new" do
      expect(get("/gardens/new")).to route_to("gardens#new")
    end

    it "routes to #show" do
      expect(get("/gardens/sunny-bed")).to route_to("gardens#show", slug: 'sunny-bed')
    end

    it "routes to #edit" do
      expect(get("/gardens/sunny-bed/edit")).to route_to("gardens#edit", slug: 'sunny-bed')
    end

    it "routes to #create" do
      expect(post("/gardens")).to route_to("gardens#create")
    end

    it "routes to #update" do
      expect(put("/gardens/sunny-bed")).to route_to("gardens#update", slug: 'sunny-bed')
    end

    it "routes to #destroy" do
      expect(delete("/gardens/sunny-bed")).to route_to("gardens#destroy", slug: 'sunny-bed')
    end
  end
end
