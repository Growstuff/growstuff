require "spec_helper"

describe AuthenticationsController do
  describe "routing" do

    it "routes to #index" do
      get("/authentications").should route_to("authentications#index")
    end

    it "routes to #new" do
      get("/authentications/new").should route_to("authentications#new")
    end

    it "routes to #show" do
      get("/authentications/1").should route_to("authentications#show", :id => "1")
    end

    it "routes to #edit" do
      get("/authentications/1/edit").should route_to("authentications#edit", :id => "1")
    end

    it "routes to #create" do
      post("/authentications").should route_to("authentications#create")
    end

    it "routes to #update" do
      put("/authentications/1").should route_to("authentications#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/authentications/1").should route_to("authentications#destroy", :id => "1")
    end

  end
end
