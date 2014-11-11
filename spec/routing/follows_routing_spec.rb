require "spec_helper"

describe FollowsController do
  describe "routing" do

    it "routes to #index" do
      get("/follows").should route_to("follows#index")
    end

    it "routes to #new" do
      get("/follows/new").should route_to("follows#new")
    end

    it "routes to #show" do
      get("/follows/1").should route_to("follows#show", :id => "1")
    end

    it "routes to #edit" do
      get("/follows/1/edit").should route_to("follows#edit", :id => "1")
    end

    it "routes to #create" do
      post("/follows").should route_to("follows#create")
    end

    it "routes to #update" do
      put("/follows/1").should route_to("follows#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/follows/1").should route_to("follows#destroy", :id => "1")
    end

  end
end
