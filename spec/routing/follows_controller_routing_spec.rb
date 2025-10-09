# frozen_string_literal: true

require "spec_helper"

describe FollowsController do
  describe "routing" do
    it "routes to #create" do
      post("/follows").should route_to("follows#create")
    end

    it "routes to #destroy" do
      delete("/follows/1").should route_to("follows#destroy", id: "1")
    end
  end
end
