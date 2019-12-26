# frozen_string_literal: true

require "rails_helper"

describe AdminController do
  describe "routing" do
    it { expect(get("/admin/")).to route_to("admin#index") }
    it { expect(get("/admin/members")).to route_to("admin/members#index") }
    it { expect(get("/admin/newsletter")).to route_to("admin#newsletter") }
  end
end
