# frozen_string_literal: true

require "spec_helper"

describe FollowsController do
  describe "routing" do
    it "routes to #create" do
      expect(post("/follows")).to route_to("follows#create")
    end

    it "routes to #destroy" do
      expect(delete("/follows/1")).to route_to("follows#destroy", id: "1")
    end
  end
end
