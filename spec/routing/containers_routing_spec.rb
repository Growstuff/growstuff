require "rails_helper"

RSpec.describe ContainersController, type: :routing do
  describe "routing" do
    it "routes to #index" do
      expect(:get => "/containers").to route_to("containers#index")
    end

    it "routes to #new" do
      expect(:get => "/containers/new").to route_to("containers#new")
    end

    it "routes to #show" do
      expect(:get => "/containers/1").to route_to("containers#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/containers/1/edit").to route_to("containers#edit", :id => "1")
    end


    it "routes to #create" do
      expect(:post => "/containers").to route_to("containers#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/containers/1").to route_to("containers#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/containers/1").to route_to("containers#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/containers/1").to route_to("containers#destroy", :id => "1")
    end
  end
end
