require 'rails_helper'

RSpec.describe "GardenTypes", type: :request do
  describe "GET /garden_types" do
    it "works! (now write some real specs)" do
      get garden_types_path
      expect(response).to have_http_status(200)
    end
  end
end
