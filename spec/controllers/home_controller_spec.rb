require 'spec_helper'

describe HomeController do

  describe "GET index" do
    it "assigns counts" do
      @planting = FactoryGirl.create(:planting)
      get :index, {}
      assigns(:garden_count).should == 2 # auto-created for member and planting
      assigns(:planting_count).should == 1
      assigns(:crop_count).should == 1
      assigns(:member_count).should == 1
    end

    it "assigns plantings" do
      @member = FactoryGirl.create(:london_member)
      @planting = FactoryGirl.create(:planting, :garden => @member.gardens.first)
      @planting.photos << FactoryGirl.create(:photo)
      @planting.save
      get :index, {}
      assigns(:plantings).should eq [@planting]
    end

    it 'assigns interesting members' do
      @member = FactoryGirl.create(:london_member)
      (1..3).each do
        FactoryGirl.create(:planting, :garden => @member.gardens.first)
      end
      get :index, {}
      assigns(:members).should eq [@member]
    end

  end
end
