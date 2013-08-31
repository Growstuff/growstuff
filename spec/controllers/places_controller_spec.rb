require 'spec_helper'

describe PlacesController do
  before :each do
    controller.stub(:current_member) { nil }
  end

  describe "GET show" do
    before(:each) do
      @member_london = FactoryGirl.create(:london_member)
      @member_south_pole = FactoryGirl.create(:south_pole_member)
    end

    it "assigns nearby members if a location is set" do
      get :show, { :place => @member_london.location }
      assigns(:nearby_members).should include @member_london
    end

    it "does not assign far members if a location is set" do
      get :show, { :place => @member_london.location }
      assigns(:nearby_members).should_not include @member_south_pole
    end
  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, { :new_place => "foo", :distance => 1000, :units => "mi" }
      response.should redirect_to place_path("foo", :distance => 1000, :units => "mi")
    end
  end
end
