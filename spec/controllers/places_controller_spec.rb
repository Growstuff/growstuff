# frozen_string_literal: true

require 'rails_helper'

describe PlacesController do
  before do
    controller.stub(:current_member) { nil }
  end

  describe "GET index" do
    before do
      @london_member = create(:london_member)
    end

    it "renders the index template for HTML request" do
      get :index
      response.should render_template(:index)
    end

    it "returns JSON with paginated located members" do
      get :index, format: :json
      response.should be_successful
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.first["login_name"]).to eq(@london_member.login_name)
      expect(json.first.keys).to match_array(%w(id login_name slug location latitude longitude))
    end
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

    it "returns JSON with nearby members" do
      get :show, params: { place: @london_member.location }, format: :json
      response.should be_successful
      json = JSON.parse(response.body)
      expect(json).to be_an(Array)
      expect(json.map { |m| m["login_name"] }).to eq([@london_member.login_name, @edinburgh_member.login_name])
      expect(json.first.keys).to match_array(%w(id login_name slug location latitude longitude))
    end
  end

  describe "GET search" do
    it "redirects to the new place" do
      get :search, params: { new_place: "foo" }
      response.should redirect_to place_path("foo")
    end
  end
end
