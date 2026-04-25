# frozen_string_literal: true

require 'rails_helper'

describe "Harvests" do
  describe "GET /harvests" do
    it "works! (now write some real specs)" do
      get harvests_path
      expect(response).to have_http_status :ok
    end
  end
end
