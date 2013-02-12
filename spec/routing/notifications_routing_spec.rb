require "spec_helper"

describe NotificationsController do
  describe "routing" do

    it "routes to #index" do
      get("/notifications").should route_to("notifications#index")
    end

    it "routes to #new" do
      get("/notifications/new").should route_to("notifications#new")
    end

    it "routes to #show" do
      get("/notifications/1").should route_to("notifications#show", :id => "1")
    end

    it "routes to #edit" do
      get("/notifications/1/edit").should route_to("notifications#edit", :id => "1")
    end

    it "routes to #create" do
      post("/notifications").should route_to("notifications#create")
    end

    it "routes to #update" do
      put("/notifications/1").should route_to("notifications#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/notifications/1").should route_to("notifications#destroy", :id => "1")
    end

  end
end
