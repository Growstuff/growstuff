require "spec_helper"

describe PhotosController do
  describe "routing" do

    it "routes to #index" do
      get("/photos").should route_to("photos#index")
    end

    it "routes to #new" do
      get("/photos/new").should route_to("photos#new")
    end

    it "routes to #show" do
      get("/photos/1").should route_to("photos#show", :id => "1")
    end

    it "routes to #edit" do
      get("/photos/1/edit").should route_to("photos#edit", :id => "1")
    end

    it "routes to #create" do
      post("/photos").should route_to("photos#create")
    end

    it "routes to #update" do
      put("/photos/1").should route_to("photos#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/photos/1").should route_to("photos#destroy", :id => "1")
    end

  end
end
