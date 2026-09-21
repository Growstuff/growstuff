# frozen_string_literal: true

require 'rails_helper'

describe "Photos" do
  include Devise::Test::IntegrationHelpers

  describe "GET /photos/:id/edit" do
    let(:photo) { create(:photo) }

    it "shows the owner a form to save changes to their photo" do
      sign_in photo.owner

      get edit_photo_path(photo)

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).to have_button('Save')
    end
  end

  describe "GET /photos" do
    it "works! (now write some real specs)" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get photos_path
      response.status.should be(200)
    end
  end
end
