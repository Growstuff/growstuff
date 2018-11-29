require 'rails_helper'

RSpec.describe "Containers", type: :request do
  describe "GET /containers" do
    it "works! (now write some real specs)" do
      get containers_path
      expect(response).to have_http_status(200)
    end
  end
end
