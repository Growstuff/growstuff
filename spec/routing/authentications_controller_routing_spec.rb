# frozen_string_literal: true

require "rails_helper"

describe AuthenticationsController do
  describe "routing" do
    it "routes to #create" do
      post("/authentications").should route_to("authentications#create")
    end

    it "routes to #destroy" do
      delete("/authentications/1").should route_to("authentications#destroy", id: "1")
    end
  end
end
