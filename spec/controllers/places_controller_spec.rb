# frozen_string_literal: true

require 'rails_helper'

describe PlacesController do
  before do
    controller.stub(:current_member) { nil }
  end

  describe "GET show" do
    before do
      @member_london = create(:london_member)
      @member_south_pole = create(:south_pole_member)
    end

    it "assigns place name" do
      get :show, params: { place: @member_london.location }
      expect(assigns(:place)).to eq @member_london.location
    end

    it "assigns nearby members" do
      get :show, params: { place: @member_london.location }
      expect(assigns(:nearby_members)).to eq [@member_london, @member_south_pole]
    end
  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, params: { new_place: "foo" }
      expect(response).to redirect_to place_path("foo")
    end
  end
end
