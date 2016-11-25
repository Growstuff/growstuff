require "rails_helper"

describe GardensController do
  describe "routing" do
    it "routes to #index" do
      get("/gardens").should route_to("gardens#index")
    end

    it "routes to #new" do
      get("/gardens/new").should route_to("gardens#new")
    end

    it "routes to #show" do
      get("/gardens/1").should route_to("gardens#show", id: "1")
    end

    it "routes to #edit" do
      get("/gardens/1/edit").should route_to("gardens#edit", id: "1")
    end

    it "routes to #create" do
      post("/gardens").should route_to("gardens#create")
    end

    it "routes to #update" do
      put("/gardens/1").should route_to("gardens#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/gardens/1").should route_to("gardens#destroy", id: "1")
    end
  end
end
