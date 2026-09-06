# frozen_string_literal: true

require "rails_helper"

describe CropsController do
  describe "routing" do
    it "routes to #index" do
      expect(get("/crops")).to route_to("crops#index")
    end

    it "routes to #new" do
      expect(get("/crops/new")).to route_to("crops#new")
    end

    it "routes to #show" do
      expect(get("/crops/lettuce")).to route_to("crops#show", slug: 'lettuce')
    end

    it { expect(get("/crops/lettuce/plantings")).to route_to("plantings#index", crop_slug: 'lettuce') }
    it { expect(get("/crops/lettuce/harvests")).to route_to("harvests#index", crop_slug: 'lettuce') }
    it { expect(get("/crops/lettuce/seeds")).to route_to("seeds#index", crop_slug: 'lettuce') }

    it "routes to #edit" do
      expect(get("/crops/lettuce/edit")).to route_to("crops#edit", slug: "lettuce")
    end

    it "routes to #create" do
      expect(post("/crops")).to route_to("crops#create")
    end

    it "routes to #update" do
      expect(put("/crops/lettuce")).to route_to("crops#update", slug: "lettuce")
    end

    it "routes to #destroy" do
      expect(delete("/crops/lettuce")).to route_to("crops#destroy", slug: "lettuce")
    end
  end
end
