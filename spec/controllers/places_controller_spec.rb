## DEPRECATION NOTICE: Do not add new tests to this file!
##
## View and controller tests are deprecated in the Growstuff project. 
## We no longer write new view and controller tests, but instead write 
## feature tests (in spec/features) using Capybara (https://github.com/jnicklas/capybara). 
## These test the full stack, behaving as a browser, and require less complicated setup 
## to run. Please feel free to delete old view/controller tests as they are reimplemented 
## in feature tests. 
##
## If you submit a pull request containing new view or controller tests, it will not be 
## merged.





require 'rails_helper'

describe PlacesController do
  before :each do
    controller.stub(:current_member) { nil }
  end

  describe "GET show" do
    before(:each) do
      @member_london = FactoryGirl.create(:london_member)
      @member_south_pole = FactoryGirl.create(:south_pole_member)
    end

    it "assigns place name" do
      get :show, { place: @member_london.location }
      assigns(:place).should eq @member_london.location
    end

    it "assigns nearby members" do
      get :show, { place: @member_london.location }
      assigns(:nearby_members).should eq [@member_london, @member_south_pole]
    end

  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, { new_place: "foo" }
      response.should redirect_to place_path("foo")
    end
  end
end
