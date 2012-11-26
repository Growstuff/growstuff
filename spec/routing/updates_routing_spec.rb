require "spec_helper"

describe UpdatesController do
  describe "routing" do

    it "routes to #index" do
      get("/updates").should route_to("updates#index")
    end

    it "routes to #new" do
      get("/updates/new").should route_to("updates#new")
    end

    it "routes to #show" do
      get("/updates/1").should route_to("updates#show", :id => "1")
    end

    it "routes to #edit" do
      get("/updates/1/edit").should route_to("updates#edit", :id => "1")
    end

    it "routes to #create" do
      post("/updates").should route_to("updates#create")
    end

    it "routes to #update" do
      put("/updates/1").should route_to("updates#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/updates/1").should route_to("updates#destroy", :id => "1")
    end

  end
end
