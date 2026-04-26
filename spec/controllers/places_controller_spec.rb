# frozen_string_literal: true

require 'rails_helper'

describe PlacesController do
  before do
    controller.stub(:current_member) { nil }
  end

  describe "GET show" do
    before do
      @london_member = create(:london_member)
      @edinburgh_member = create(:edinburgh_member)
    end

    it "assigns place name" do
      get :show, params: { place: @london_member.location }
      assigns(:place).should eq @london_member.location
    end

    it "assigns nearby members" do
      get :show, params: { place: @london_member.location }
      assigns(:nearby_members).should eq [@london_member, @edinburgh_member]
    end
  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, params: { new_place: "foo" }
      response.should redirect_to place_path("foo")
    end
  end
end
