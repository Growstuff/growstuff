require 'rails_helper'

describe PlacesController do
  before :each do
    controller.stub(:current_member) { nil }
  end

  describe "GET show" do
    before(:each) do
      @member_london = FactoryBot.create(:london_member)
      @member_south_pole = FactoryBot.create(:south_pole_member)
    end

    it "assigns place name" do
      get :show, place: @member_london.location
      assigns(:place).should eq @member_london.location
    end

    it "assigns nearby members" do
      get :show, place: @member_london.location
      assigns(:nearby_members).should eq [@member_london, @member_south_pole]
    end
  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, new_place: "foo"
      response.should redirect_to place_path("foo")
    end
  end
end
