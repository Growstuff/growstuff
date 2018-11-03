# frozen_string_literal: true

require 'rails_helper'

describe "ScientificNames" do
  describe "GET /scientific_names" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get scientific_names_path
      response.status.should be(200)
    end
  end
end
