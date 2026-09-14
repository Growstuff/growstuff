# frozen_string_literal: true

require "rails_helper"

describe AuthenticationsController do
  describe "routing" do
    it "routes to #create" do
      expect(post("/authentications")).to route_to("authentications#create")
    end

    it "routes to #destroy" do
      expect(delete("/authentications/1")).to route_to("authentications#destroy", id: "1")
    end
  end
end
