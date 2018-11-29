require "rails_helper"

describe ContainersController do
  describe "routing" do
    it "routes to #index" do
      get("/containers").should route_to("containers#index")
    end

    it "routes to #new" do
      get("/containers/new").should route_to("containers#new")
    end

    it "routes to #show" do
      get("/containers/1").should route_to("containers#show", id: "1")
    end

    it "routes to #edit" do
      get("/containers/1/edit").should route_to("containers#edit", id: "1")
    end

    it "routes to #create" do
      post("/containers").should route_to("containers#create")
    end

    it "routes to #update" do
      put("/containers/1").should route_to("containers#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/containers/1").should route_to("containers#destroy", id: "1")
    end
  end
end
