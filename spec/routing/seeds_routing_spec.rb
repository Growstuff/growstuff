require "rails_helper"

describe SeedsController do
  describe "routing" do
    it "routes to #index" do
      get("/seeds").should route_to("seeds#index")
    end

    it "routes to #new" do
      get("/seeds/new").should route_to("seeds#new")
    end

    it "routes to #show" do
      get("/seeds/1").should route_to("seeds#show", id: "1")
    end

    it "routes to #edit" do
      get("/seeds/1/edit").should route_to("seeds#edit", id: "1")
    end

    it "routes to #create" do
      post("/seeds").should route_to("seeds#create")
    end

    it "routes to #update" do
      put("/seeds/1").should route_to("seeds#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/seeds/1").should route_to("seeds#destroy", id: "1")
    end
  end
end
